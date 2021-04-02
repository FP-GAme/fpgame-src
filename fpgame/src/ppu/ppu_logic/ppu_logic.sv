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

    vram_if.usr vram_ppu_ifP_usr
);

    logic [9:0] pmxr_rowram_wrdata;
    logic [8:0] pmxr_rowram_wraddr;
    logic pmxr_rowram_wren;

    // TODO instantiate 2 Tile-Engines, 1 Sprite Engine, 1 Pixel Mixer.
    // TODO Figure out whether row ram should be here or in ppu.sv

    /*tile_engine bgte (
        .clk,
        .rst_n,

        .row(), // TODO this must be attached to the row we must prep (see pixel_mixer)
        .tilram_addr(vram_ppu_ifP_usr.tilram_addr_a),
        .tilram_rddata(vram_ppu_ifP_usr.tilram_rddata_a),
        .patram_addr(vram_ppu_ifP_usr.patram_addr_a),
        .patram_rddata(vram_ppu_ifP_usr.tilram_rddata_a),

        // From Double-Buffered Control Registers
        .scroll(), //TODO
        .enable(), //TODO

        // from/to Pixel Mixer
        .prep,         // TODO, this is essentially the row-buffer swap signal.
        .pixel_addr(), // TODO, give this to pixel_mixer's address line, which is also connected to all of the other pixel_engines at once
        .pixel_data(), // TODO, give this to pixel_mixer's pixel_data_bgte or similar port name.
        .done() // TODO, give this to pixel mixer, who should latch this done value

    );*/
    /*tile_engine fgte (

    );*/
    /*sprite_engine spre (

    );*/
    /*pixel_mixer pmxr (

    );*/

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
    assign vram_ppu_ifP_usr.palram_addr_b = 'X;
    assign vram_ppu_ifP_usr.palram_wren_b = 1'b0;
    assign vram_ppu_ifP_usr.palram_wrdata_a = 'X;
    assign vram_ppu_ifP_usr.palram_wrdata_b = 'X;
    assign vram_ppu_ifP_usr.palram_byteena_b = 'X;

endmodule : ppu_logic