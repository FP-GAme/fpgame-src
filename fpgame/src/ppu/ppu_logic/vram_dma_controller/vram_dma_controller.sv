/* vram_dma_controller.sv
 * Controls the VRAM DMA.
 * Seriously. That's it.
 */
/* Overview
 * Just after VRAM-SYNC, if the DMA Source address has been changed, this module will program the
 *   DMA-Engine and start the transfer.
 *
 * We always transfer with the following settings:
 * writeaddress: 0                 (The destination VRAM always begins at address 0)
 * readaddress:  cpu_vram_src_addr (The CPU's source VRAM is set by a MMIO-accessible Register)
 * length:       53568             (This is the number of bytes in a full VRAM)
 */

module vram_dma_controller (
    input  logic clk,
    input  logic rst_n,
    input  logic dma_finish_irq,
    output logic dma_busy
);

endmodule : vram_dma_controller