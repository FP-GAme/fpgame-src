/* ppu_dma_interface.sv
 * Exposes the DMA Engine's control registers and interrupt to our custom logic.
 */

module ppu_dma_interface (
    input  logic         clock_clk,
    input  logic         reset_reset,

    // DMA control register access
    output logic [2:0]   avm_dma_address,
    output logic         avm_dma_write_n,
    output logic [31:0]  avm_dma_writedata,
    input  logic         avm_dma_waitrequest,

    // DMA finished interrupt
    input  logic         interrupt_receiver_irq,

    // Conduit exposed to custom FPGA logic
    input  logic [2:0]   coe_dma_wraddr,
    input  logic         coe_dma_wren,
    input  logic [31:0]  coe_dma_wrdata,
    output logic         coe_dma_waitrequest,
    output logic         coe_dma_finish_irq
);

    assign avm_dma_address     = coe_dma_wraddr;
    assign avm_dma_write_n     = ~coe_dma_wren;
    assign avm_dma_writedata   = coe_dma_wrdata;
    assign coe_dma_waitrequest = avm_dma_waitrequest;
    assign coe_dma_finish_irq  = interrupt_receiver_irq;

endmodule : ppu_dma_interface
