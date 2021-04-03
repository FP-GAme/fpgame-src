/* ppu_logic.sv
 * TODO: Joseph... plz document.
 */

module ppu_logic (
    input logic clk,
    input logic rst_n,

    // from/to HDMI video output
    output logic [9:0]  hdmi_rowram_rddata,
    input  logic [8:0]  hdmi_rowram_rdaddr,
    output logic [63:0] hdmi_palram_rddata,
    input  logic [8:0]  hdmi_palram_rdaddr,
    input  logic        rowram_swap,
    input  logic [7:0]  next_row,

    vram_if.usr vram_ppu_ifP_usr
);

    logic [8:0] pixel_addr;
    logic [7:0] fg_pixel_data;
    logic [7:0] bg_pixel_data;
    logic [8:0] sp_pixel_data;
    logic [1:0] sp_pixel_prio;
    logic       bgte_done;
    logic       fgte_done;
    logic       spre_done;
    logic [9:0] pmxr_rowram_wrdata;
    logic [8:0] pmxr_rowram_wraddr;
    logic       pmxr_rowram_wren;

    // TODO instantiate 2 Tile-Engines, 1 Sprite Engine, 1 Pixel Mixer.
    // TODO Figure out whether row ram should be here or in ppu.sv
    tile_engine #( .FG(1'b0) ) bgte (
        .clk,
        .rst_n,
        .next_row,
        .tilram_addr(vram_ppu_ifP_usr.tilram_addr_a),
        .tilram_rddata(vram_ppu_ifP_usr.tilram_rddata_a),
        .patram_addr(vram_ppu_ifP_usr.patram_addr_a),
        .patram_rddata(vram_ppu_ifP_usr.patram_rddata_a),
        .scroll(32'b0),      // TODO. From MMIO Ctrl Regs.
        .enable(1'b1),      // TODO. From MMIO Ctrl Regs.
        .prep(rowram_swap), // Start preparing buffer when the swap occurs
        .pixel_addr,
        .pixel_data(bg_pixel_data),
        .done(bgte_done)
    );
    /*tile_engine fgte (

    );*/
    /*sprite_engine spre (

    );*/

    // TODO remove once FG Tile Engine and Sprite Engine are instantiated. These are dummy engines:
    assign fgte_done = 1'b1;
    assign spre_done = 1'b1;
    assign sp_pixel_data = 9'd0;
    assign sp_pixel_prio = 2'b00;
    assign fg_pixel_data = 8'b0;

    pixel_mixer pmxr (
        .clk,
        .rst_n,
        .pixel_addr,
        .fg_pixel_data,
        .bg_pixel_data,
        .sp_pixel_data,
        .sp_pixel_prio,
        .bgte_done,
        .fgte_done,
        .spre_done,
        .pmxr_rowram_wrdata,
        .pmxr_rowram_wraddr,
        .pmxr_rowram_wren

    );

    // Depending on which rowram is visible to the hardware, we must multiplex inputs and outputs.
    // By default (rowram_swapped=0), rr1 is accessible by hdmi_video_output and rr2 is accessible
    //   by the pixel mixer.
    row_ram_swap rrs (
        .clk,
        .rst_n,
        .rowram_swap,
        .hdmi_rowram_rddata,
        .hdmi_rowram_rdaddr,
        .pmxr_rowram_wrdata,
        .pmxr_rowram_wraddr,
        .pmxr_rowram_wren
    );

    // ========================
    // === VRAM Assignments ===
    // ========================

    // hdmi_video_output reads directly from the PPU-Facing Palette RAM
    assign hdmi_palram_rddata = vram_ppu_ifP_usr.palram_rddata_a;
    assign vram_ppu_ifP_usr.palram_addr_a = hdmi_palram_rdaddr;
    assign vram_ppu_ifP_usr.palram_wren_a = 1'b0;
    
    // PPU-Facing RAM is never written to by ppu_logic. Most of these are don't-cares.
    assign vram_ppu_ifP_usr.tilram_wren_a   = 1'b0;
    assign vram_ppu_ifP_usr.tilram_wren_b   = 1'b0;
    assign vram_ppu_ifP_usr.tilram_wrdata_a = 'X;
    assign vram_ppu_ifP_usr.tilram_wrdata_b = 'X;

    assign vram_ppu_ifP_usr.patram_wren_a   = 1'b0;
    assign vram_ppu_ifP_usr.patram_wren_b   = 1'b0;
    assign vram_ppu_ifP_usr.patram_wrdata_a = 'X;
    assign vram_ppu_ifP_usr.patram_wrdata_b = 'X;

    // Only 1 port (port a) is used as Read-Only for palette data (by the hdmi_video_output)
    assign vram_ppu_ifP_usr.palram_addr_b    = 'X;
    assign vram_ppu_ifP_usr.palram_wren_b    = 1'b0;
    assign vram_ppu_ifP_usr.palram_wrdata_a  = 'X;
    assign vram_ppu_ifP_usr.palram_wrdata_b  = 'X;
    assign vram_ppu_ifP_usr.palram_byteena_b = 'X;

endmodule : ppu_logic