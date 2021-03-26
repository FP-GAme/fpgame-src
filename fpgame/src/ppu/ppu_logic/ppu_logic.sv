/* ppu_logic.sv
 * TODO: Joseph... plz document.
 */

module ppu_logic (
    input logic clk,
    input logic rst_n,

    // from/to HDMI video output
    output logic [9:0]  rowram_rddata,
    input  logic [8:0]  rowram_rdaddr,
    output logic [63:0] palram_rddata,
    input  logic [8:0]  palram_rdaddr,
    input  logic        rowram_swap,

    vram_if.usr vram_ppu_ifP_usr
);

    // TODO instantiate 2 Tile-Engines, 1 Sprite Engine, 1 Pixel Mixer.
    // TODO Figure out whether row ram should be here or in ppu.sv

    // TODO: Move into ppu_logic eventually?
    // TODO: This should be a row-ram interface. In reality, 2 row-rams should exist. One for the PPU-logic to write to, and one for the hdmi_video_output to read from
    row_ram rr (
        .address_a(rowram_rdaddr),
        .address_b(9'b0),
        .clock(clk),
        .data_a(10'b0), // TODO Change
        .data_b(10'b0), // TODO Change
        .wren_a(1'b0), // TODO Change
        .wren_b(1'b0), // TODO Change
        .q_a(rowram_rddata),
        .q_b()
    );

    assign palram_rddata = vram_ppu_ifP_usr.palram_rddata_a; // TODO: Check over later
    assign vram_ppu_ifP_usr.palram_addr_a = palram_rdaddr;   // TODO: Also check over later

endmodule : ppu_logic