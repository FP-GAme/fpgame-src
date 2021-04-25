/**@file ppu.c
 * 
 * @brief Kernel module for the FP-GAme PPU
 * 
 * This kernel module implements the FP-GAme PPU driver.
 * To this kernel module, the PPU interface is simply a collection of MMIO-accessible control
 *   registers, plus one IRQ.
 * To the users, the PPU is interacted with by writing to a kernel-managed "virtual VRAM". When the
 *   user is finished making changes, they call the ppu_draw() user library function to have their
 *   frame displayed. In reality, when ppu_draw() is called, the kernel initiates DMA transfer when
 *   it is able.
 * The most important two rules of CPU-to-PPU VRAM DMA:
 *   1. The kernel can only initiate DMA transfer of the virtual VRAM once per interrupt received.
 *      For example, the kernel can start a DMA transfer by writing the physical address of the
 *      virtual VRAM into an PPU control register, but must wait to do so again until after the PPU
 *      sends its IRQ, notifying this module that the frame has been transferred and will be drawn,
 *      and that the PPU is ready to accept a new DMA source address.
 *   2. After initiating the DMA transfer, this module must lock access to the virtual VRAM,
 *      preventing any users from making adjustments while DMA transfer is occuring.
 *
 * @author Joseph Yankel
 * Credit to Andrew Spaulding: Lots of code was copied from APU and Controller Kernel Module
 */

/* === Includes === */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/types.h>
#include <linux/stat.h>
#include <linux/io-mapping.h>
#include <linux/dma-mapping.h>
#include <linux/interrupt.h>
#include <linux/device.h>
#include <linux/kdev_t.h>

#include <linux/fp-game/drv_ppu.h>


/* === Definitions === */
/** @brief PPU MMIO Control Registers physical base address */
#define PPU_MMIO_BASE 0xFF200030
/** @brief Overall-size/span of the PPU MMIO Control Registers */
#define PPU_MMIO_SIZE 0x50

/** @brief Offsets from the PPU_MMIO_BASE for each PPU Control Register */
//@{
#define PPU_DMA_ADDR_OFFSET 0x00
#define PPU_BGSCROLL_OFFSET 0x10
#define PPU_FGSCROLL_OFFSET 0x20
#define PPU_BGCOLOR_OFFSET  0x30
#define PPU_ENABLE_OFFSET   0x40
//@}

/** @brief SDRAM Register Map Base Address (Physical) */
#define SDR_BASE 0xFFC20000
/** @brief fpgaportrst register offset from @ref SDR_BASE */
#define FPGAPORTRST_OFFSET 0x5080
/** @brief Size (in Bytes) of fpgaportrst register */
#define FPGAPORTRST_SIZE 0x4


/* === Module Functions === */
static int ppu_probe(struct platform_device *pdev);
static int ppu_remove(struct platform_device *pdev);
static int ppu_open(struct inode *inode, struct file *file);
static int ppu_release(struct inode *inode, struct file *file);
static ssize_t ppu_write(struct file *file, const char __user *buf, size_t len, loff_t *offset);
static long ppu_ioctl(struct file *file, unsigned ioctl_num, unsigned long ioctl_param);
static irqreturn_t ppu_irq(int irq, void *dev_id);


/* === Helper Functions === */
static void mmio_write(unsigned addr, unsigned val);


/* === Static Variables === */
static struct io_mapping *ppu_io;

/** @brief The original pointer to the kernel's VRAM copy. Guaranteed to be 8B-aligned */
static u64 *vram_base_v;

/** @brief Base address to the kernel's VRAM copy, aligned to 16B */
static u64 *vram_addr_v; // A virtual address

/** @brief Original DMA Address handle to the base of kernel VRAM. Guaranteed to be 8B-aligned
 *
 * We do not use this as our actual VRAM address if it is not aligned to 16B. See vram_addr_p
 *   instead, which is vram_base_p or a pointer aligned to the next 16B boundary.
 */
static dma_addr_t vram_base_p;

/** @brief DMA Address handle to the base of kernel VRAM, aligned to 16B
 *
 * We send this address to the dma_addr_reg register whenever we want to begin a DMA transfer.
 */
static dma_addr_t vram_addr_p; // A physical address

/** @brief PPU IRQ which signals that it is safe to unlock the kernel VRAM and/or begin a new DMA */
static int dma_rdy_irq;

/** @brief Lock for accessing the PPU */
static atomic_t ppu_lock;

/** @brief Lock for VRAM writes during DMA transfer */
static atomic_t vram_lock;

/** @brief Device Class for this driver */
struct class *cl;

/** @brief Device Tree Devices Support List
 *
 * Defines the device our kernel module is compatible with, which Linux checks against the Device
 *   Tree to find out which driver (us) to call probe on so we can register our interrupt handler.
 */
static const struct of_device_id ppu_dt_ids[] = {
    {.compatible = "altr,socfpga-fpgameppu"},
    {},
};

/** @brief Platform driver structure
 *
 * Set up this kernel module as the platform driver for the PPU platform device.
 */
static struct platform_driver ppu_platform = {
    .driver = {
        .name = PPU_DEV_NAME,
        .owner = THIS_MODULE,
        .of_match_table = of_match_ptr(ppu_dt_ids),
    },
    .probe = ppu_probe,
    .remove = ppu_remove,
};

/** @brief PPU file operations structure
 *
 * This structure is used to inform the linux kernel which system calls our device driver
 *   implements.
 */
static struct file_operations fops = {
    .open = ppu_open,
    .release = ppu_release,
    .write = ppu_write,
    .unlocked_ioctl = ppu_ioctl,
};


/* === Function Implementations === */
/** @brief Initialize the PPU kernel module.
 * @param pdev Platform device for the PPU.
 * @return 0 on success or a negative integer on failure.
 */
static int ppu_probe(struct platform_device *pdev)
{
    // Temporary mapping to the SDRAM Controller registers
    void __iomem *fpgaportrst_io;

    dev_t dev;

    // Register our driver with the kernel
    if (register_chrdev(PPU_MAJOR_NUM, PPU_DEV_NAME, &fops) < 0)
    {
        printk(KERN_ALERT "FP-GAme PPU Driver failed to register char device");
        return -1;
    }

    ppu_io = io_mapping_create_wc(PPU_MMIO_BASE, PPU_MMIO_SIZE);

    // Allocate Virtual VRAM. Must be coherent so that changes are immediately readable by the PPU's
    //   DMA Engine.
    vram_base_v = dma_alloc_coherent(&pdev->dev, VRAM_SIZE+8, &vram_base_p, GFP_KERNEL);
    if (vram_base_v == NULL) {
        printk(KERN_ALERT "FP-GAme PPU Driver failed to alloc virtual VRAM");
        return -1;
    }
    // Ensure the physical (DMA-accessible) address is aligned to 16B. We do this by allocating an
    //   extra 8B initially and then choosing where to start our VRAM based on the base address.
    if ( ((unsigned int)vram_base_p & 0xF) != 0 )
    {
        // The DMA address is not aligned! Increment both the kernel's VRAM base address and the
        //   DMA address by 8B to achieve alignment.
        vram_addr_v = vram_base_v+1;
        vram_addr_p = vram_base_p+1;
        // Note that it doesn't matter that the kernel's virtual VRAM address is 16B aligned, only
        //   that the DMA's physical VRAM address is 16B aligned.
    }
    else
    {
        // DMA address is aligned. Thanks, Linux.
        vram_addr_v = vram_base_v;
        vram_addr_p = vram_base_p;
    }

    // initialize VRAM and PPU write locks to 0 (available for write)
    atomic_set(&ppu_lock, 0);
    atomic_set(&vram_lock, 0);

    dma_rdy_irq = platform_get_irq(pdev, 0);
    if (request_irq(dma_rdy_irq, ppu_irq, 0, PPU_DEV_NAME, ppu_irq) < 0)
    {
        printk(KERN_ALERT "FP-GAme PPU Driver failed to register IRQ");
        return -1;
    }

    // Write 1s to specific bits in the fpgaportrst register to enable the ports used by our PPU's
    //   DMA-Engine
    if ( (fpgaportrst_io = ioremap(SDR_BASE + FPGAPORTRST_OFFSET, FPGAPORTRST_SIZE)) == NULL )
    {
        printk(KERN_ALERT "FP-GAme PPU Driver failed to map fpgaportrst physical address");
        return -1;
    }
    writel(0x0103, fpgaportrst_io);
    iounmap(fpgaportrst_io);

    // Create the device in /dev
    cl = class_create(THIS_MODULE, PPU_DEV_NAME);
    dev = MKDEV(PPU_MAJOR_NUM, 0);
    device_create(cl, NULL, dev, NULL, PPU_DEV_NAME);

    return 0;
}

/** @brief Cleans up this PPU kernel module.
 * @param pdev The platform device of the PPU.
 * @return 0.
 */
static int ppu_remove(struct platform_device *pdev)
{
    dev_t dev;
    dev = MKDEV(PPU_MAJOR_NUM, 0);
    device_destroy(cl, dev);
    class_destroy(cl);

    unregister_chrdev(PPU_MAJOR_NUM, PPU_DEV_NAME);
    io_mapping_free(ppu_io);
    dma_free_coherent(&pdev->dev, VRAM_SIZE+8, vram_base_v, vram_base_p);
    free_irq(dma_rdy_irq, NULL);

    return 0;
}

/** @brief Attempts to open the PPU module file.
 *
 * If the PPU has already been opened by another process, fails.
 *
 * @param inode Ignored.
 * @param file Ignored.
 * @return 0 on success, -1 on error.
 */
static int ppu_open(struct inode *inode, struct file *file)
{
    return (atomic_xchg(&ppu_lock, 1) == 0) ? 0 : -EBUSY;
}

/** @brief Closes the PPU device file.
 *
 * Calling this function releases the PPU lock, allowing other processes to use the PPU.
 *
 * @return 0 on success, -1 on error.
 */
static int ppu_release(struct inode *inode, struct file *file)
{
    if (atomic_xchg(&ppu_lock, 0) == 0) {
        printk(KERN_ALERT "Close called on PPU when it wasn't open!");
    }

    return 0;
}

/** @brief Writes to the kernel's VRAM
 *
 * This function returns with a failure condition when this module has locked PPU writes (during DMA
 *   transfer).
 *
 * @param file Ignored.
 * @param buf The user-supplied write data.
 * @param len The size of user-supplied write data.
 * @param offset Start position to write to.
 * @return 0 on success, or a negative integer on error.
 */
static ssize_t ppu_write(struct file *file, const char __user *buf, size_t len, loff_t *offset)
{
    u8 *addr;

    // Check if write is within bounds:
    if (*offset + len > VRAM_SIZE)
    {
        return -EINVAL;
    }

    // Try to acquire the VRAM write lock. If we cannot, tell the user we are busy.
    if (atomic_xchg(&vram_lock, 1) == 1) {
        printk(KERN_ALERT "FP-GAme PPU Driver write busy");
        return -EBUSY;
    }

    // Write user's data to the Kernel VRAM at the specified offset
    addr = (u8*)vram_addr_v + (unsigned)(*offset);
    if (copy_from_user(addr, buf, len) != 0)
    {
        printk(KERN_ALERT "FP-GAme PPU Driver write failed!");
        atomic_xchg(&vram_lock, 0);
        return -EFAULT; // THIS SHOULD NEVER HAPPEN, since we checked offset earlier.
    }

    // Ensure our changes are seen before any other write occurs (especially the DMA_ADDR MMIO!)
    wmb();

    // increment current position in file
    *offset += len;

    atomic_xchg(&vram_lock, 0);

    return len; // We will have written exactly len bytes on success
}

/** @brief Handles an IOCTL call to the PPU module.
 *
 * @param file Ignored.
 * @param ioctl_num The ioctl command number.
 * @param ioctl_param ioctl parameter.
 * @return 0 on success, or -1 on failure.
 */
static long ppu_ioctl(struct file *file, unsigned ioctl_num, unsigned long ioctl_param)
{
    int ret;

    // Try to acquire the VRAM write lock. If we cannot, tell the user we are busy.
    if (atomic_xchg(&vram_lock, 1) == 1) { return -EBUSY; }

    ret = 0;
    switch (ioctl_num)
    {
        case IOCTL_PPU_UPDATE:
            mmio_write(PPU_DMA_ADDR_OFFSET, vram_addr_p);
            // After writing the DMA address, we must leave the vram write lock locked.
            // We should not be able to write again until the IRQ unlocks it for us.
            return ret; // Simply return without unlocking.
        case IOCTL_PPU_SET_BGSCROLL:
            mmio_write(PPU_BGSCROLL_OFFSET, (unsigned)ioctl_param);
            break;
        case IOCTL_PPU_SET_FGSCROLL:
            mmio_write(PPU_FGSCROLL_OFFSET, (unsigned)ioctl_param);
            break;
        case IOCTL_PPU_SET_BGCOLOR:
            mmio_write(PPU_BGCOLOR_OFFSET, (unsigned)ioctl_param);
            break;
        case IOCTL_PPU_SET_ENABLE:
            mmio_write(PPU_ENABLE_OFFSET, (unsigned)ioctl_param);
            break;
        default:
            ret = -EINVAL;
            break;
    }

    atomic_set(&vram_lock, 0);
    return ret;
}

/** @brief Handles the PPU IRQ
 *
 * The PPU sends only 1 IRQ, the dma_rdy_irq. This IRQ tells us that we can unlock user access to
 *   the kernel's VRAM copy, and also that we can start another DMA transfer when we please.
 *
 * @param irq Ignored.
 * @param dev_id Ignored.
 * @return IRQ_HANDLED, signaling the successful handling of the irq.
 */
static irqreturn_t ppu_irq(int irq, void *dev_id)
{
    // unlock VRAM writes
    atomic_set(&vram_lock, 0);

    return IRQ_HANDLED;
}


/* === Helper Implementations === */
/** @brief Writes a value to mmio.
 * @param offset The offset from the mmio base to write to.
 * @param val The value to be written.
 * @return Void.
 */
static void mmio_write(unsigned offset, unsigned val)
{
    void *addr;

    /* WARNING: This function disables preemption! */
    addr = io_mapping_map_atomic_wc(ppu_io, offset);
    writel(val, addr);
    io_mapping_unmap_atomic(addr);
}


/* === Extra Kernel Module Stuff === */
// Short-hand used to replace init and exit functions, since our module does nothing special there.
module_platform_driver(ppu_platform);

MODULE_AUTHOR("Joseph Yankel");
MODULE_DESCRIPTION("FP-GAme Device Driver used by FP-GAme Library to control PPU");
MODULE_LICENSE("GPL");