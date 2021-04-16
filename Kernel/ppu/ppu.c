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
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/platform_device.h>

#include <linux/of.h>
#include <linux/of_device.h>

/** @brief Address of the Lightweight H2F Avalon/AXI Bus, where the PPU Control Registers live */
#define LW_H2F_MMIO_BASE         (0xFF200000U)
#define DMA_SRC_ADDR_PIO_OFFSET  (0x00000030U)
#define BGSCROLL_PIO_OFFSET      (0x00000040U)
#define FGSCROLL_PIO_OFFSET      (0x00000050U)
#define BGCOLOR_PIO_OFFSET       (0x00000060U)
#define ENABLE_PIO_OFFSET        (0x00000070U)

<0xFC000000, 0xD140>, // TODO. I want to allocate 0xD140 Bytes for vram...

/** @brief The name of the ppu device. */
#define PPU_DEV_NAME "fp_game_ppu"

/* Module Functions */
static int ppu_probe(struct platform_device *pdev);
static int ppu_remove(struct platform_device *pdev);

/**@brief Device Tree Devices Support List
 *
 * Defines the device our kernel module is compatible with, which Linux checks against the Device
 *   Tree to find out which driver (us) to call probe on so we can register our interrupt handler.
 */
static const struct of_device_id ppu_dt_ids[] = {
    {.compatible = "altr,socfpga-fpgameppu"},
    {},
};

// Inform Linux of the devices this driver supports.
MODULE_DEVICE_TABLE(of, ppu_dt_ids); // of means "use Open Firmware matching mechanism"

/**@brief Platform driver structure.
 *
 * Set up this kernel module as the platform driver for the PPU platform device.
 */
static struct platform_driver ppu_platform = {
    .probe = ppu_probe,
    .remove = ppu_remove,
    .driver = {
        .name = PPU_DEV_NAME,
        .owner = THIS_MODULE,
        .of_match_table = of_match_ptr(ppu_dt_ids),
    },
};

/**@brief Initialize the PPU kernel module.
 * @param pdev Platform device for the PPU.
 * @return 0 on success or a negative integer on failure.
 */
static int ppu_probe(struct platform_device *pdev)
{
    // Extract resources from device tree
    struct resource 

    // Create a big-chungus virtual VRAM
    // Ensure it is aligned to 16B. We do this by allocating an extra 8B and choosing where to start
    //   our VRAM based on the start address XXXX returns us.
    return 0;
}

/**@brief Cleans up this PPU kernel module.
 * @param pdev The platform device of the PPU.
 * @return 0.
 */
static int ppu_remove(struct platform_device *pdev)
{
    // TODO
	return 0;
}

// Short-hand used to replace init and exit functions, since our module does nothing special there.
module_platform_driver(ppu_platform);

MODULE_AUTHOR("Joseph Yankel");
MODULE_AUTHOR("Andrew Spaulding"); // Plenty of code was copied from APU Kernel Module
MODULE_DESCRIPTION("FP-GAme Device Driver used by FP-GAme Library to control PPU");
MODULE_LICENSE("GPL");