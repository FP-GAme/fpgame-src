/* ppu_logic.sv
 *
 * Returns color data to the HDMI Video Output based on the PPU-Facing VRAM and buffered PPU Control
 *   registers
 */

module ppu_logic (
    input logic clk,
    input logic rst_n,

    // from/to HDMI video output
    output logic [9:0]  hdmi_rowram_rddata,
    input  logic [8:0]  hdmi_rowram_rdaddr,
    output logic [23:0] hdmi_color_rddata,
    input  logic [9:0]  hdmi_color_rdaddr,
    input  logic        rowram_swap,
    input  logic [7:0]  next_row,

    vram_if_ppu_facing.usr vram_ppu_ifP_usr,

    input  logic [31:0] bgscroll,
    input  logic [31:0] fgscroll,
    input  logic [2:0]  enable,
    input  logic [23:0] bgcolor
);

    logic [8:0] pmxr_pixel_addr;
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

    // from/to Sprite-Engine and Pattern-RAM Address Controller Mux
    logic spre_start;
    logic swap_patram_mux;
    logic [11:0] bgte_patram_addr, spre_patram_addr;

    // for displaying background color when an hdmi_color_rdaddr comes in as 0s.
    logic p1_show_bgcolor, show_bgcolor;
    // for preserving the LSB of a 32-bit read to downconvert a 64-bit read
    logic p1_color_sel, color_sel;

    tile_engine #( .FG(1'b0) ) bgte (
        .clk,
        .rst_n,
        .next_row,
        .tilram_addr(vram_ppu_ifP_usr.tilram_addr_a),
        .tilram_rddata(vram_ppu_ifP_usr.tilram_rddata_a),
        .patram_addr(bgte_patram_addr),
        .patram_rddata(vram_ppu_ifP_usr.patram_rddata_a), // Shared with sprite engine "spre"
        .scroll(bgscroll),
        .enable(enable[0]),
        .prep(rowram_swap), // Start preparing buffer when the swap occurs
        .pmxr_pixel_addr,
        .pmxr_pixel_data(bg_pixel_data),
        .done(bgte_done)
    );
    tile_engine #( .FG(1'b1) ) fgte (
        .clk,
        .rst_n,
        .next_row,
        .tilram_addr(vram_ppu_ifP_usr.tilram_addr_b),
        .tilram_rddata(vram_ppu_ifP_usr.tilram_rddata_b),
        .patram_addr(vram_ppu_ifP_usr.patram_addr_b),
        .patram_rddata(vram_ppu_ifP_usr.patram_rddata_b),
        .scroll(fgscroll),
        .enable(enable[1]),
        .prep(rowram_swap), // Start preparing buffer when the swap occurs
        .pmxr_pixel_addr,
        .pmxr_pixel_data(fg_pixel_data),
        .done(fgte_done)
    );
    sprite_engine spre (
        .clk,
        .rst_n,
        .next_row,
        .sprram_addr_a(vram_ppu_ifP_usr.sprram_addr_a),
        .sprram_rddata_a(vram_ppu_ifP_usr.sprram_rddata_a),
        .sprram_addr_b(vram_ppu_ifP_usr.sprram_addr_b),
        .sprram_rddata_b(vram_ppu_ifP_usr.sprram_rddata_b),
        .patram_addr(spre_patram_addr), // Multiplexed in with bgte_patram_addr
        .patram_rddata(vram_ppu_ifP_usr.patram_rddata_a), // Shared with background tile-engine
        .prep(spre_start), // Start whenever tile-engines end
        .enable(enable[2]),
        .pmxr_pixel_addr,
        .pmxr_pixel_data(sp_pixel_data),
        .pmxr_pixel_prio(sp_pixel_prio),
        .done(spre_done)
    );

    pixel_mixer pmxr (
        .clk,
        .rst_n,
        .pixel_addr(pmxr_pixel_addr),
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


    // ====================================
    // === HDMI Output VRAM Connections ===
    // ====================================
    // hdmi_video_output reads from the PPU-Facing Palette RAM, but they send an 10-bit address
    //   since they expect 32-bit reads. Our actual Palette RAM uses 64-bit reads, however, and so
    //   we must send it a 9-bit address (preserving the missing LSB via pipelining so that we can
    //   choose between two returned 32-bit values).
    assign hdmi_color_rddata = (show_bgcolor) ? bgcolor : 
                               (color_sel)    ? vram_ppu_ifP_usr.palram_rddata_a[55:32] :
                                                vram_ppu_ifP_usr.palram_rddata_a[23:0];
    assign vram_ppu_ifP_usr.palram_addr_a = hdmi_color_rdaddr[9:1]; // Address not including the LSB
    assign vram_ppu_ifP_usr.palram_wren_a = 1'b0;


    // ==============================
    // === Other VRAM Assignments ===
    // ==============================
    // PPU-Facing RAM is never written to by ppu_logic. Most of these are don't-cares.
    assign vram_ppu_ifP_usr.tilram_wren_a   = 1'b0;
    assign vram_ppu_ifP_usr.tilram_wren_b   = 1'b0;
    assign vram_ppu_ifP_usr.tilram_wrdata_a =  'X;
    assign vram_ppu_ifP_usr.tilram_wrdata_b =  'X;

    assign vram_ppu_ifP_usr.patram_wren_a   = 1'b0;
    assign vram_ppu_ifP_usr.patram_wren_b   = 1'b0;
    assign vram_ppu_ifP_usr.patram_wrdata_a =  'X;
    assign vram_ppu_ifP_usr.patram_wrdata_b =  'X;

    // Port a and b are used as Read-Only for sprite data (by Sprite Engine)
    assign vram_ppu_ifP_usr.sprram_wren_a   = 1'b0;
    assign vram_ppu_ifP_usr.sprram_wren_b   = 1'b0;
    assign vram_ppu_ifP_usr.sprram_wrdata_a =  'X;
    assign vram_ppu_ifP_usr.sprram_wrdata_b =  'X;

    // Only 1 port (port a) is used as Read-Only for palette data (by the hdmi_video_output)
    assign vram_ppu_ifP_usr.palram_addr_b    =  'X;
    assign vram_ppu_ifP_usr.palram_wren_b    = 1'b0;
    assign vram_ppu_ifP_usr.palram_wrdata_a  =  'X;
    assign vram_ppu_ifP_usr.palram_wrdata_b  =  'X;

    // When fgte = 1, the sprite-engine should control the address line to Pattern-RAM
    // swap_patram_mux - Multiplexes inputs (BG Tile Engine and Sprite Engine) to the 1st port of
    //   Pattern-RAM
    assign vram_ppu_ifP_usr.patram_addr_a = (swap_patram_mux) ? spre_patram_addr : bgte_patram_addr;


    // ==================================
    // === Sprite Engine Timing Logic ===
    // ==================================
    // Start sprite engine when tile engines finish (only one of fgte or bgte done is sufficient)
    assign spre_start = fgte_done;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            swap_patram_mux <= 1'b0;
        end
        else begin
            // Warning, this introduces a 1 cycle delay from the start signal to when the
            //   Pattern-RAM is available to the Sprite Engine. Since the Sprite Engine will not
            //   immediately read from Pattern-RAM upon start, this should be fine.
            if (spre_start) swap_patram_mux <= 1'b1;

            // Warning, this introduces a 1 cycle delay from the start signal to when the
            //   Pattern-RAM is available to the BG-Tile Engine. Since the Tile Engines will not
            //   immediately read from Pattern-RAM upon start, this should be fine.
            else if (rowram_swap) swap_patram_mux <= 1'b0;
            else swap_patram_mux <= swap_patram_mux;

            // Note that these events are mutually exclusive. Only 1 will happen at any given
            //   time.
        end
    end


    // ============================================
    // === Show Default Background Color Signal ===
    // ============================================
    // This signal is extracted from hdmi_palram_addr = '0. However, it must be delayed to the mux
    //   which determines the final pixel color read (which occurs with a read-latency of 1 cycle)
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            p1_show_bgcolor <= 1'b0;
            show_bgcolor <= 1'b0;

            p1_color_sel <= 1'b0;
            color_sel <= 1'b0;
        end
        else begin
            p1_show_bgcolor <= (hdmi_color_rdaddr == '0);
            show_bgcolor <= p1_show_bgcolor;

            p1_color_sel <= hdmi_color_rdaddr[0];
            color_sel <= p1_color_sel;
        end
    end

endmodule : ppu_logic