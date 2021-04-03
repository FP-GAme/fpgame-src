/* tile_engine.sv
 * Implements a Tile-Engine (reusable for both Foreground and Background Tiles)
 */
/* Overview
 * TODO: Document this JOE
 */
/* All About Scrolling
 * 
 * Scrolling is accomplished using an Double-Buffered 32-bit MMIO register set by the CPU during
 *   cpu_busy_write, and updated in this Tile-Engine afterwards during VBLANK.
 * 
 * scroll holds both x and y scroll values in the following pattern [31:0]:
 * [ _ _ _ _ _ _ _ Y Y Y Y Y Y Y Y Y _ _ _ _ _ _ _ X X X X X X X X X ]
 *
 * scroll_x is scroll[8:0], a 9-bit number which can be split into a tile_scroll_x and
 *   pixel_scroll_x.
 * tile_scroll_x is scroll_x[8:3], a 6-bit number which tells us which out of the 64 tiles is
 *   the first tile on the left of the screen. This, along with tile_scroll_y effectively determines
 *   our tile_address into Tile RAM.
 * pixel_scroll_x is the remaining 3 bits: scroll_x[2:0]. This tells us which out of the 8 pixels in
 *   the first tile is to be displayed first. Once we have chosen our 328 pixel (41-tile) row, this
 *   3-bit scroll determines which 320 pixels (40-tiles) are to be finally displayed to the screen.
 *
 * scroll_y is simply scroll[24:16]. This, similarly to scroll_x, can be split into a tile_scroll_y
 *   and pixel_scroll_y.
 * tile_scroll_y is scroll_y[8:3], a 6-bit number. This number tells us which out of the 64 tile
 *   rows to address in Tile RAM.
 * pixel_scroll_y is scroll_y[2:0]. We use this 3-bit number to determine which out of the 8 pixel
 *   rows to address in a tile row chosen by tile_scroll_y.
 *
 * For more detailed notes on how scrolling affects the accesses to Tile-RAM and Pattern-RAM, see
 *   the comments in this file under the tilram_fetcher and patram_fetcher modules.
 *
 */
/* What does Enable do?
 * If enable == 0, then this Pixel-Engine will still do everything it normally does. However, when
 *   asked for pixel values, the Pixel-Engine will always respond with 0s (transparent). This
 *   effectively renders this BG/FG layer as transparent.
 */
/* How do Mirror Bits Work?
 * Tile RAM (see vram.sv) is made up of entries of tile-data. Each tile-data entry contains 2-bits
 *   which determine whether the tile is flipped vertically, horizontally, both, or neither.
 *
 * How is this actually accomplished?
 * It affects which pixels from Pattern RAM are buffered in the local pattern ram buffer.
 * When we use the base address for a tile from tile-data buffered in the local tile ram buffer, we
 *   have 4 possible choices for which 2 rows of that tile to grab (Recall 64-bit accesses means
 *   that we will store 2 rows (32-bits/row at 8px/row * 4b/px)). Example illustration:
 *
 * Tile at base address A:
 *   A   |  ROW_0  |  |  ROW_1  |
 *   A+1 |  ROW_2  |  |  ROW_3  |
 *   A+2 |  ROW_4  |  |  ROW_5  |
 *   A+3 |  ROW_6  |  |  ROW_7  |
 * Which choice should we make? The answer is dependent on the y-pixel-scroll and y-mirror. Without
 *   considering y-mirror, we calculate the row to choose as follows:
 * y-pixel-scroll is 3-bits, which determine which out of 8-rows is to be displayed on a given tile
     for a given scan-line. Since we must chose 2 rows, we effectively cut our choices in half. So
     we take y-pixel-scroll / 2 to give us the offset from the tile's base address which determines
     which 2 rows to buffer.
 * If we now apply the y-mirror. Our choice is the "opposite" of what it would have been.
 * Mathematically, this is the bitwise inverse of the 2-bit result we obtained without y-mirror.
 */

module tile_engine #(
    parameter FG = 1'b0 // Set to 0 to address BG Tile RAM; 1 to address FG Tile RAM. (1 BIT NUMBER)
) (
    input  logic clk,
    input  logic rst_n,

    // From ppu_logic (and technically hdmi_video_output)
    input  logic [7:0]  next_row,
    output logic [10:0] tilram_addr,
    input  logic [63:0] tilram_rddata,
    output logic [11:0] patram_addr,
    input  logic [63:0] patram_rddata,

    // From Double-Buffered Control Registers
    input  logic [31:0] scroll,
    input  logic        enable,

    // from/to Pixel Mixer
    input  logic       prep,
    input  logic [8:0] pixel_addr,
    output logic [7:0] pixel_data,
    output logic       done
);

    enum {TILENG_IDLE, TILENG_PREP} state;
    logic n_done;

    // address to trt (acting as our address buffer)
    logic [5:0] patram_fetcher_addr_abuf; // multiplexed into trt's address line

    // ==============================
    // === Scrolling Calculations ===
    // ==============================
    logic [8:0] scroll_x;
    assign scroll_x = scroll[8:0];
    logic [8:0] effective_pixel; // Given a row of pixels, which pixel is accessed?
    assign effective_pixel = pixel_addr + scroll_x; // Overflow is a feature
    logic [5:0] effective_tile; // Given a row of tiles, which tile is accessed?
    assign effective_tile = effective_pixel[8:3];

    logic [8:0] scroll_y;
    assign scroll_y = scroll[24:16];
    logic [8:0] effective_pixelrow; // Given scanline and scroll, which row of pixels are we on?
    assign effective_pixelrow = scroll_y + next_row; // Overflow is welcome here
    logic [5:0] effective_tilerow; // Given which pixelrow we are on, which tilerow is it a part of?
    assign effective_tilerow = effective_pixelrow[8:3]; // The tile for the current row + scrolling

    // ===========
    // === trt ===
    // ===========
    /* trt Module Overview
     *
     * After start signal is sent to Tile-Engine, this tile-data row-buffer is filled with an entire
     *   row's worth of tile-data entries from Tile-RAM (+3 extras due to 64-bit read data width).
     *
     * The tile-data in this buffer is used later to index into and read from Pattern RAM.
     * This RAM is read from by Pixel-Mixer to get the color palette associated with a given pixel.
     */

    // Permanently attached to syncwriter/(tilram_fetcher)
    logic [3:0]  trt_addr_a;
    logic [63:0] trt_data_a;
    logic        trt_wren_a;

    // Multiplexed between the pixel-mixer (row+scrolling) (IDLE) and patram_fetcher (PREP)
    logic [5:0] trt_addr_b;
    assign trt_addr_b = (state == TILENG_PREP) ? patram_fetcher_addr_abuf : effective_tile;

    logic [15:0] trt_rddata_b; // Technically is hard-wired to both pixel-mixer and patram_fetcher

    tileng_rowdata_tilram trt (
        .address_a(trt_addr_a),
        .address_b(trt_addr_b),
        .clock(clk),
        .data_a(trt_data_a),
        .data_b('X),         // Ignored since nothing writes to this port
        .wren_a(trt_wren_a),
        .wren_b(1'b0),       // Disable writes to this port.
        .q_a(),              // Left empty since nothing reads from the 64-bit port.
        .q_b(trt_rddata_b)
    );

    // ======================
    // === tilram_fetcher ===
    // ======================
    /* tilram_fetcher Module Overview
     *
     * When the prep signal is given, we will use a sync-writer module to copy linearly from the
     *   Tile-RAM to our local tile-data buffer, which holds just enough data to allow us to display
     *   the current row of pixels.
     *
     * We require 41 tiles, since 40 8px tile segments are visible on the screen on a single row,
     *   but since our accesses are 64-bit, and the Tile-Data is 16-bits per tile, we will end up
     *   fetching 44 tiles, which means 3 tiles of data are wasted.
     *
     * We will tell the sync writer to start at tile_base_addr and copy 11/16 adjacent tile chunks.
     * If the start address is high enough such that the sync writer would begin to read the tiles
     *   belonging to the next row (or overflow), then we wrap around to tile at the beginning of
     *   the current row.
     */
    /* Concrete Example of Address Calculation and Tile Fetch
     * Example: There are 64 tiles, we read in chunks of 4 tiles. And we need 41, so we must make
     *   11 accesses to Tile-RAM. Say the scroll_x is 319 (decimal), scroll_y is 50(decimal), and
     *   the current scanline/row is 120.
     * Calculate the base address for the current row: This is where the sync-writer will start the
     *   copy, (plus some offset dependent on scroll_x, but more on this after).
     * base_addr = (scroll_y + current_row)/8 (truncated) * 16 = 21 * 4 = 336, (decimal);
     * Note, there are only 16 entries per row of tiles in Tile-RAM, since our accesses are 64-bit.
     * If our accesses were 16-bit (1 address per-tile instead of 1 address per 4 tiles)), we would
     *   need to multiply scroll_y by 64 to get the base address.
     * Now, consider our scroll_x. Which tile should be the first tile to copy?
     *   -> 319px / 8px/tile = 39 tiles (truncated). We should start at the 39th tile in this row,
     *   since we have some pixels that need to be displayed in the 39th tile.
     * This calculation can be formalized as follows: chunk_offset = scroll_x >> 3;
     * However, remember that our accesses are 64-bits wide, so we copy chunks of 4 tiles at a time.
     * Which tile chunk does the 39th tile belong to? This is the first chunk we must copy...
     *   -> 39th tile / 4 tiles per chunk (truncated) = 9th chunk.
     * Thus, we must tell the sync-writer to start at base_addr + chunk_offset = 336 + 9 = 345.
     * The sync writer will then copy 11 tile-data chunks, starting from address 345 (decimal).
     * We will have copied chunks 345, 346, 347, 348, 349, 350, 351, 336, 337, 338, 339.
     * Notice that at the last chunk in a row (351), we must wrap back around to the start of the
     *   row (336) (recall that each tile row has 64 tiles, and thus 16 tile chunks). This allows
     *   us to implement scrolling of larger worlds.
     */
    
    logic tilram_fetcher_start;
    logic tilram_fetcher_done;
    logic [3:0] tilram_fetcher_partaddr;
    logic [3:0] tilram_fetcher_tilechunk; // Where in a row of 16 tile chunks to start copying?
    assign tilram_fetcher_tilechunk = scroll_x[8:5] + tilram_fetcher_partaddr; // Overflow is fine
    assign tilram_addr = {FG[0], effective_tilerow, tilram_fetcher_tilechunk};

    sync_writer #(
        .DATA_WIDTH(64),
        .ADDR_WIDTH(4), // Tile-RAM has 11-bit addresses, though we keep the 7MSBs fixed
        .MAX_ADDR(10) // Make 11 reads, since we need 41 tiles for scrolling (3 unused extra)
    ) tilram_fetcher (
        .clk,
        .rst_n,
        .sync(tilram_fetcher_start),
        .done(tilram_fetcher_done),
        .clr_done(tilram_fetcher_done),
        .addr_from(tilram_fetcher_partaddr), // This is a partial address (counter).
        .wren_from(),                 // ppu_logic automatically sets tile-ram wren to 0 for us
        .rddata_from(tilram_rddata),
        .addr_to(trt_addr_a),
        .byteena_to(),                // trt doesn't have a byteenable. Leave floating (unused)
        .wrdata_to(trt_data_a),
        .wren_to(trt_wren_a)
    );

    // ===========
    // === trp ===
    // ===========
    /* trp Module Overview
     *
     * After the trt module finishes gathering tile-data, pattern addresses in those tile-data
     *   entries are used to download pixel values for the current row into this local RAM.
     * We must store the equivalent of 41 rows of pixel data, or 41*8 = 328 pixels.
     * However, due to how Pattern memory is laid out, as well as due to our 64-bit readdata width,
     *   we will inevitably need to make 41 separate accesses to Pattern RAM, each containing extra
     *   pixel rows we do not need.
     * Each access to Pattern RAM gives us 2 8-pixel-4bpp rows in a target tile (who's base address
     *   is determined by the address stored in trt).
     */

    // Permanently attached to indirect_syncwriter/(patram_fetcher)
    logic [5:0]  trp_addr_a;
    logic [63:0] trp_wrdata_a;
    logic        trp_wren_a;
    
    // Permanently attached to pixel-mixer (through some special access logic for scrolling)
    logic [9:0]  trp_addr_b;
    // effective_pixelrow[0] toggles between the 1st and 2nd rows (32b each) we buffered
    // pixel_addr[8:3] selects 1 out of 64 (technically 41) tile-rows (tile-slices) of pixels
    // pixel_addr[2:0] selects 1 out of the 8 pixels
    assign trp_addr_b = { pixel_addr[8:3], effective_pixelrow[0], pixel_addr[2:0] };
    logic [3:0]  trp_rddata_b;
    
    tileng_rowdata_patram trp (
        .address_a(trp_addr_a),
        .address_b(trp_addr_b),
        .clock(clk),
        .data_a(trp_wrdata_a),
        .data_b('X),         // Read-only port for pixel-mixer
        .wren_a(trp_wren_a),
        .wren_b(1'b0),       // Read-only port for pixel-mixer
        .q_a(),              // Port-A is used by patram_fetcher, which only writes (leave unused)
        .q_b(trp_rddata_b)
    );

    // ======================
    // === patram_fetcher ===
    // ======================
    /* patram_fetcher Module Overview
     * To fetch specific rows of pixels belonging to specific tiles from Pattern RAM, we employ the
     *   indirect_sync_writer module. This allows us to read an address from our local tile-data
     *   buffer, and use that address to index into Pattern RAM and copy pattern-data for that tile.
     */

    logic patram_fetcher_start;
    assign patram_fetcher_start = tilram_fetcher_done; // Start fetch as soon as tilram fetch done

    logic patram_fetcher_done;

    // What tile should we copy pixel rows from?
    logic [9:0] pattern_addr_base;
    assign pattern_addr_base = trt_rddata_b[15:6];

    // Vertical mirror bit. Used to determine pattern_addr_offset
    logic y_mirror;
    assign y_mirror = trt_rddata_b[1];

    // Given a tile's base address into pattern RAM, which 2/8 rows to copy to our local pattern buf
    logic [1:0] pattern_addr_offset;
    assign pattern_addr_offset = (y_mirror) ? ~(effective_pixelrow[2:1]) : effective_pixelrow[2:1];

    logic [11:0] rddata_abuf;
    assign rddata_abuf = {pattern_addr_base, pattern_addr_offset};

    indirect_sync_writer #(
        .ABUF_ADDR_WIDTH(6),
        .ABUF_NUM_ADDR(41),
        .DATA_WIDTH(64),
        .SRC_ADDR_WIDTH(12),
        .TARG_ADDR_WIDTH(6)
    ) patram_fetcher (
        .clk,
        .rst_n,
        .sync(patram_fetcher_start),
        .done(patram_fetcher_done),
        .addr_abuf(patram_fetcher_addr_abuf), // This is connected to trt_addr_b during prep
        .rddata_abuf,
        .addr_src(patram_addr),
        .wren_src(), // We only read from Pattern-RAM. This is already taken care of by ppu_logic
        .rddata_src(patram_rddata),
        .addr_targ(trp_addr_a),
        .wrdata_targ(trp_wrdata_a),
        .wren_targ(trp_wren_a)
    );

    // =============================
    // === Output to Pixel-Mixer ===
    // =============================
    // This contains valid data with 1-cycle of read latency during the IDLE state
    // The MSBs form a color palette address, the LSBs form the pixel color
    assign pixel_data = {trt_rddata_b[5:2], trp_rddata_b};

    // ===========
    // === FSM ===
    // ===========

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            state <= TILENG_IDLE;
            n_done <= 1'b0;
            done <= 1'b0;
            tilram_fetcher_start <= 1'b0;
        end
        else begin
            done <= n_done; // Delay the done signal by 1 so that we are in IDLE when it is asserted
            if (state == TILENG_IDLE) begin
                n_done <= 1'b0;
                if (prep) begin 
                    state <= TILENG_PREP;
                    tilram_fetcher_start <= 1'b1;
                end
            end
            else begin // state == PREP
                tilram_fetcher_start <= 1'b0; // reset start signal now that it has been asserted
                if (patram_fetcher_done) begin
                    n_done <= 1'b1;
                    state <= TILENG_IDLE;
                end
            end
        end
    end

endmodule : tile_engine