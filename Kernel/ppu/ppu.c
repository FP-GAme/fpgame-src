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
#include <linux/platform_device.h>

/** @brief Address of the Lightweight H2F Avalon/AXI Bus, where the PPU Control Registers live */
#define LW_H2F_MMIO_BASE         (0xFF200000U)
#define DMA_SRC_ADDR_PIO_OFFSET  (0x00000030U)
#define BGSCROLL_PIO_OFFSET      (0x00000040U)
#define FGSCROLL_PIO_OFFSET      (0x00000050U)
#define BGCOLOR_PIO_OFFSET       (0x00000060U)
#define ENABLE_PIO_OFFSET        (0x00000070U)

/* Module Functions */
static int ppu_probe(struct platform_device *pdev);
static int ppu_remove(struct platform_device *pdev);

/**@brief Interrupt table
 *
 * Defines the device our kernel module is compatible with, which Linux checks against the Device
 *   Tree to find out which driver (us) to call probe on so we can register our interrupt handler.
 */
static const struct of_device_id ppu_int_table[] = {
    {.compatible = "altr,socfpga-fpgameppu"},
    {},
};

/**@brief Platform driver structure.
 *
 * Set up this kernel module as the platform driver for the PPU platform device.
 */
static struct platform_driver ppu_platform = {
    .driver = {
        .name = PPU_DEV_NAME,
        .owner = THIS_MODULE,
        .of_match_table = of_match_ptr(ppu_int_table),
    },
    .probe = ppu_probe,
    .remove = ppu_remove,
};

/**@brief Initialize the PPU kernel module.
 * @param pdev Platform device for the PPU.
 * @return 0 on success or a negative integer on failure.
 */
static int ppu_probe(struct platform_device *pdev)
{
    // TODO: Create a big-chungus virtual VRAM
    return 0;
}

/**@brief Cleans up this PPU kernel module.
 * @param pdev The platform device of the PPU.
 * @return 0.
 */
static int apu_remove(struct platform_device *pdev)
{
    // TODO
	return 0;
}



module_platform_driver(ppu_platform);

MODULE_AUTHOR("Joseph Yankel");
MODULE_DESCRIPTION("FP-GAme PPU Driver");
MODULE_LICENSE("GPL");