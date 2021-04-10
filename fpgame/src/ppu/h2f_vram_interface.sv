/* h2f_vram_interface.sv
 * Exposes the CPU-Facing VRAM Write Port to the DMA Engine. Essentially acts as a "wire" for all of
 *   the necessary signals for the VRAM write port, directly connecting them to the Avalon Bus.
 */

module h2f_vram_interface (
    input  logic        clock_clk,
    input  logic        reset_reset,

    // Write port to VRAM
    input  logic [11:0]  avs_vram_address,
    input  logic         avs_vram_write,
    input  logic [127:0] avs_vram_writedata,

    // ppu conduit
    output logic [11:0]  coe_hps_vram_wraddr,
    output logic         coe_hps_vram_wren,
    output logic [127:0] coe_hps_vram_wrdata
);

    assign coe_hps_vram_wraddr = avs_vram_address;
    assign coe_hps_vram_wren = avs_vram_write;
    assign coe_hps_vram_wrdata = avs_vram_writedata;

endmodule : h2f_vram_interface
