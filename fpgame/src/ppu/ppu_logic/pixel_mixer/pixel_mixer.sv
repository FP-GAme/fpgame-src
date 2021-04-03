/* pixel_mixer.sv
 * Implements the Pixel Mixer
 */
/* Overview
 * The Pixel Mixer idles until all Pixel-Engines raise a done signal (this will always occur a
 *   constant # of cycles after the rowbuffer swap signal has been received).
 * Then, for each of the 320 pixels in a row, the Pixel Mixer will ask the Pixel Engines (BG-Tile,
 *   FG-Tile, and Sprite), for the following information in parallel:
 * 1. A 4-bit color for the pixel.
 * 2. A 4-bit palette address for the pixel (relative to the Pixel Engine's base address in Palette
 *    RAM). (Sprites are a special case where 5-bits of palette address are used)
 * 3. Just for the Sprite Engine: A 2-bit priority encoded as follows:
 *    * 00 for behind BG,
 *    * 01 for behind FG,
 *    * 1X for in front of both FG and BG
 *
 * To achieve this, the Pixel Engines are given the current pixel's column (0-319). They must
 *   respond with the data on the next clock cycle (behaving exactly like a On-Chip RAM).
 * 
 * The Pixel Mixer receives this information and chooses the final 10-bit pixel data to write to the
 *   rowbuffer. For more information on this logic, see the pixel_priority module.
 *
 * The final 10-bit pixel data has the following format (LSB to MSB):
 * * 4-bit color address into palette
 * * 4-bit palette address into Palette RAM
 * * 2-bit source address (00 BG Palette, 01 FG Palette, or 1X Sprite Palette). This acts as 2 more
 * *   bits of address into the Palette RAM.
 */

module pixel_mixer (

    input  logic clk,
    input  logic rst_n,

    // from/to Pixel-Engines
    output logic [8:0] pixel_addr,
    input  logic [7:0] fg_pixel_data,
    input  logic [7:0] bg_pixel_data,
    input  logic [8:0] sp_pixel_data,
    input  logic [1:0] sp_pixel_prio,
    input  logic       bgte_done,
    input  logic       fgte_done,
    input  logic       spre_done,

    // from/to final rowbuf
    output logic [9:0] pmxr_rowram_wrdata,
    output logic [8:0] pmxr_rowram_wraddr,
    output logic       pmxr_rowram_wren
);

enum {PMXR_WAIT, PMXR_FETCH} state, n_state;

// These are latched-in/preserved versions of the original signals
// They hold their value until the next rowram_swap
logic bgte_done_rec, n_bgte_done_rec;
logic fgte_done_rec, n_fgte_done_rec;
logic spre_done_rec, n_spre_done_rec;

// Holds the previous pixel_addr. Used to delay the write address from the pixel read address
logic [8:0] pixel_addr_buffer;

// signals for counter
logic pixel_counter_clr;
logic pixel_counter_en;

// wire groups split from pixel_data
logic [3:0] fg_color;
logic [3:0] fg_palette;
logic [3:0] bg_color;
logic [3:0] bg_palette;
logic [3:0] sp_color;
logic [4:0] sp_palette; // Sprites have access to 1 more chunk of palette data.

// Determine priority and the final pixel data
// Source=1X sprites, source=01 FG, source=00 BG.
logic [1:0] final_source;
localparam [1:0] SRC_BG = 2'b00;
localparam [1:0] SRC_FG = 2'b01;
localparam [1:0] SRC_SP = 2'b10; // the LSB will be replaced with the palette address MSB
always_comb begin
    fg_color = fg_pixel_data[3:0];
    bg_color = bg_pixel_data[3:0];
    sp_color = sp_pixel_data[3:0];
    fg_palette = fg_pixel_data[7:4];
    bg_palette = bg_pixel_data[7:4];
    sp_palette = sp_pixel_data[8:4];

    final_source = SRC_BG;
    if (sp_color == 4'b0) begin
        if (fg_color != 4'b0) final_source = SRC_FG;
    end
    else begin
        if (sp_pixel_prio[1]) final_source = SRC_SP;
        else if (sp_pixel_prio == 2'b01) begin
           if (fg_color == 4'b0) final_source = SRC_SP;
           else final_source = SRC_FG;
        end
        else if (sp_pixel_prio == 2'b00) begin
            if (fg_color == 4'b0) begin
                if (bg_color == 4'b0) final_source = SRC_SP;
            end
            else final_source = SRC_FG;
        end
    end

    if (final_source == SRC_BG) // Note! Show the default universal bg color if bg_color is 0
        pmxr_rowram_wrdata = (bg_color == 4'b0) ? 10'b0 : {final_source, bg_palette, bg_color};
    else if (final_source == SRC_FG)
        pmxr_rowram_wrdata = {final_source, fg_palette, fg_color};
    else // (final_source == SRC_SP)
        pmxr_rowram_wrdata = {1'b1, sp_palette, sp_color};
    // Sprites are a special case where they have 1 additional bit of palette address
end

// Pixel-Address counter. We must address pixels 0-319.
up_counter #( .WIDTH(9) ) pixel_addr_counter (
    .clk,
    .rst_n,
    .clr(pixel_counter_clr),
    .en(pixel_counter_en),
    .count(pixel_addr)
);

// Handle state, pixel & address counter signals, and write enable
localparam [8:0] MAX_PIXEL_ADDR = 319;
always_comb begin
    if (state == PMXR_WAIT) begin // We are either done, or waiting for pixel-engines to finish
        pmxr_rowram_wren = 1'b0;  // While waiting, do not write.
        pixel_counter_clr = 1'b1; // Keep pixel counter cleared to prepare for fetch state.
        pixel_counter_en = 1'b0;

        n_state = (bgte_done_rec && fgte_done_rec && spre_done_rec) ? PMXR_FETCH : PMXR_WAIT;
    end
    else begin // PMXR_FETCH
        // Enable counting and writing during fetch state:
        pixel_counter_clr = 1'b0;
        pixel_counter_en = 1'b1;
        pmxr_rowram_wren = 1'b1;

        // avoid overflowing
        if (pixel_addr == MAX_PIXEL_ADDR) pixel_counter_en = 1'b0;

        n_state = (pmxr_rowram_wraddr == MAX_PIXEL_ADDR) ? PMXR_WAIT : PMXR_FETCH;
    end
end

// Handle done signal hold mechanism
always_comb begin
    n_bgte_done_rec = bgte_done_rec;
    n_fgte_done_rec = fgte_done_rec;
    n_spre_done_rec = spre_done_rec;
    
    if (state == PMXR_WAIT) begin
        if (bgte_done) n_bgte_done_rec = 1'b1;
        if (fgte_done) n_fgte_done_rec = 1'b1;
        if (spre_done) n_spre_done_rec = 1'b1;
    end
    else begin // PMXR_FETCH
        // reset the done signals
        n_bgte_done_rec = 1'b0;
        n_fgte_done_rec = 1'b0;
        n_spre_done_rec = 1'b0;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        state <= PMXR_WAIT;
        bgte_done_rec <= 1'b0;
        fgte_done_rec <= 1'b0;
        spre_done_rec <= 1'b0;
        pixel_addr_buffer <= 9'b0;
        pmxr_rowram_wraddr <= 9'b0;
    end
    else begin
        // Update state
        state <= n_state;

        // delay the write address by 2 cycles
        pixel_addr_buffer <= pixel_addr;
        pmxr_rowram_wraddr <= pixel_addr_buffer;

        // Update done signal preservation mechanism
        bgte_done_rec <= n_bgte_done_rec; 
        fgte_done_rec <= n_fgte_done_rec; 
        spre_done_rec <= n_spre_done_rec;
    end
end

endmodule : pixel_mixer