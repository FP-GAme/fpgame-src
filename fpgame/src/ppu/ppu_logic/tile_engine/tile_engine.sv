/* tile_engine.sv
 * Implements a Tile-Engine (reusable for both Foreground and Background Tiles)
 */
/* Overview
 * The Tile-Engine displays tile-graphics with color palettes, locations, and mirror-transformations
 *   given by Tile-RAM, with the actual graphics coming from Pattern-RAM.
 *
 * When the prep signal is sent, the Tile-Engine will prepare its internal row-buffers by reading
 *   from Tile-RAM and Pattern-RAM. When finished, it will assert the done signal, allowing the
 *   Pixel-Mixer to read pixel values and color palette addresses from it like a RAM.
 */
/* Scrolling Theory
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
 * tilerow_scroll_y is scroll_y[8:3], a 6-bit number. This number tells us which out of the 64 tile-
 *   rows to address in Tile RAM.
 * pixelrow_scroll_y is scroll_y[2:0]. We use this 3-bit number to determine which out of the 8
 *   pixel-rows to address in a tile-row chosen by tile_scroll_y.
 * Notice the distinction between tile-row and pixel-row. "Tile-Rows" refer to the 64 rows of tiles,
 *   each containing 8 pixel rows, whereas "Pixel-Rows" refers to the 512 rows of 512 pixels each.
 *
 * The actual scrolling implementation in this Tile-Engine (especially x-scrolling) is not exactly
 *   as straightforward as the notes above. This is due to how our memories are 64-bit data-width,
 *   which causes us to fetch chunks of data, meaning we cannot address individual pixels or tiles
 *   as easily.
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
 * Mirror bits affect which pixels from Pattern RAM are buffered in patram_rbuf as well as their
 *   ordering.
 * When we use the base address for a tile from tilram_rbuf, we have 4 possible choices for which
 *   2 rows of that tile to grab. (Recall 64-bit accesses means that we will store 2 rows
 *   (32-bits/row at 8px/row * 4b/px)).
 *
 * Example illustration:
 * Tile at base address A:
 *   A   |  ROW_0  |  |  ROW_1  |
 *   A+1 |  ROW_2  |  |  ROW_3  |
 *   A+2 |  ROW_4  |  |  ROW_5  |
 *   A+3 |  ROW_6  |  |  ROW_7  |
 * Which choice should we make? The answer is dependent on the y-pixel-scroll and y-mirror. Without
 *   considering y-mirror, we calculate the row to choose as follows:
 * y-pixel-scroll is 3-bits, which determine which out of 8-rows is to be displayed on a given tile
 *   for a given scan-line. Since we must chose 2 rows, we effectively cut our choices in half. So
 *   we take y-pixel-scroll / 2 to give us the offset from the tile's base address which determines
 *   which 2 rows to buffer.
 * If we now apply the y-mirror. Our choice is the "opposite" of what it would have been.
 * Mathematically, this is the bitwise inverse of the 2-bit result we obtained without y-mirror.
 */

module tile_engine #(
    parameter FG = 1'b0 // Set to 0 to address BG Tile RAM; 1 to address FG Tile RAM. (1 BIT NUMBER)
) (
    input  logic clk,
    input  logic rst_n,

    // From ppu_logic (and technically hdmi_video_output)
    input  logic [7:0]  next_row,       // The row we should prepare to display
    output logic [10:0] tilram_addr,    // Address to Tile-RAM
    input  logic [63:0] tilram_rddata,  // Read-data from Tile-RAM
    output logic [11:0] patram_addr,    // Address to Pattern-RAM
    input  logic [63:0] patram_rddata,  // Read-data from Pattern-RAM

    // From Double-Buffered Control Registers
    input  logic [31:0] scroll,
    input  logic        enable,

    // from/to Pixel Mixer
    input  logic       prep,            // Start preparing a row corresponding to next_row
    input  logic [8:0] pmxr_pixel_addr,
    output logic [7:0] pmxr_pixel_data,
    output logic       done
);

    // =========================
    // === Tile-Engine State ===
    // =========================
    enum {TILENG_IDLE, TILENG_PREP} state;
    logic n_done;


    // ==============================
    // === Scrolling Calculations ===
    // ==============================
    logic [8:0] scroll_x;
    assign scroll_x = scroll[8:0];
    logic [5:0] tile_scroll_x;
    assign tile_scroll_x = scroll_x[8:3];
    logic [2:0] pixel_scroll_x;
    assign pixel_scroll_x = scroll_x[2:0];

    // Since tilram_rbuf contains groups of 4 tiles, PMXR needs to know which tile in the first
    //   group of 4 to display first. pmxr_initial_tile designates this initial tile offset wrt. to
    //   beginning of tilram_rbuf.
    logic [1:0] initial_tile;
    assign initial_tile = tile_scroll_x[1:0];

    // The pixel in the current row chosen by pixel_scroll_x and pmxr's pixel_addr
    logic [8:0] pixel_addr;
    assign pixel_addr = pmxr_pixel_addr + pixel_scroll_x;

    // The current tile chosen by the starting point (pmxr_initial_tile) and pmxr's pixel address
    logic [5:0] tile_addr;
    assign tile_addr = initial_tile + pixel_addr[8:3];

    logic [8:0] scroll_y;
    assign scroll_y = scroll[24:16];

    // Given scanline (next_row) and scroll, which row of pixels are we on?
    logic [8:0] pixelrow;
    assign pixelrow = scroll_y + next_row; // Overflow is welcome here

    // Given which pixelrow we are on, which tilerow is it a part of?
    logic [5:0] tilerow;
    assign tilerow = pixelrow[8:3]; // The tile for the current row + scrolling


    // ===================
    // === tilram_rbuf ===
    // ===================
    /* tilram_rbuf Module Overview
     *
     * After start signal is sent to Tile-Engine, this tile-data row-buffer is filled with an entire
     *   row's worth of tile-data entries from Tile-RAM (+3 extras due to 64-bit read data width).
     *
     * The tile-data in this buffer is used later by the patram_fetcher to index into and read from
     *   Pattern RAM.
     * This RAM is read from by Pixel-Mixer to get the color palette associated with a given pixel.
     */

    // Permanently attached to syncwriter/(tilram_fetcher)
    logic [3:0]  tilram_rbuf_fetcher_wraddr;
    logic [63:0] tilram_rbuf_fetcher_wrdata;
    logic        tilram_rbuf_fetcher_wren;

    // Read address multiplexed between the pixel-mixer (IDLE) and patram_fetcher (PREP)
    logic [5:0] tilram_rbuf_rdaddr;

    // Hard-wired to both pixel-mixer and patram_fetcher
    logic [15:0] tilram_fetcher_pmxr_rddata;

    tileng_rowdata_tilram tilram_rbuf (
        .address_a(tilram_rbuf_fetcher_wraddr),
        .address_b(tilram_rbuf_rdaddr),
        .clock(clk),
        .data_a(tilram_rbuf_fetcher_wrdata),
        .data_b('X),                         // Ignored since nothing writes to this port
        .wren_a(tilram_rbuf_fetcher_wren),
        .wren_b(1'b0),                       // Disable writes to this port.
        .q_a(),                              // Left empty since nothing reads from the 64-bit port.
        .q_b(tilram_fetcher_pmxr_rddata)
    );


    // ======================
    // === tilram_fetcher ===
    // ======================
    /* tilram_fetcher Module Overview
     *
     * When the prep signal is given, we will use a sync-writer module to copy linearly from the
     *   Tile-RAM to our local tile-data buffer, tilram_rbuf, which holds just enough data to allow
     *   us to display the current row of pixels.
     *
     * We require 41 tiles, since 40 8px tile segments are visible on the screen on a single row,
     *   but since our accesses are 64-bit, and the Tile-Data is 16-bits per tile, we will end up
     *   fetching 44 tiles, which means 3 tiles of data are unused at any given time.
     *
     * We will tell the sync writer to start at tile_base_addr and copy 11/16 adjacent tile chunks.
     * If the start address is high enough such that the sync writer would begin to read the tiles
     *   belonging to the next row (or overflow), then we wrap around to tile at the beginning of
     *   the current row.
     */

    logic tilram_fetcher_start;
    logic tilram_fetcher_done;

    // The partial address (counter) generated from the sync-writer module. The full address
    //   (tilram_addr) incorporates scrolling and whether this is a BG or FG Tile-Engine.
    logic [3:0] tilram_fetcher_partaddr;

    // Where in a row of 16 tile chunks to start copying?
    logic [3:0] tilram_fetcher_tilechunk;
    assign tilram_fetcher_tilechunk = tile_scroll_x[5:2] + tilram_fetcher_partaddr; // Overflow is fine // TODO: tile_scroll_x[3:0] old: scroll_x[8:5]

    // Final address to tile-RAM incorporating scrolling and BG/FG status
    assign tilram_addr = {FG[0], tilerow, tilram_fetcher_tilechunk};

    sync_writer #(
        .DATA_WIDTH(64),
        .ADDR_WIDTH(4), // Tile-RAM has 11-bit addresses, though we keep the 7MSBs fixed
        .MAX_ADDR(10)   // Make 11 reads, since we need 41 tiles for scrolling (3 unused extra)
    ) tilram_fetcher (
        .clk,
        .rst_n,
        .sync(tilram_fetcher_start),
        .done(tilram_fetcher_done),
        .clr_done(tilram_fetcher_done),
        .addr_from(tilram_fetcher_partaddr),    // This is a partial address (counter).
        .wren_from(),                           // ppu_logic already sets tile-RAM wren to 0 for us
        .rddata_from(tilram_rddata),
        .addr_to(tilram_rbuf_fetcher_wraddr),
        .byteena_to(),                          // tilram_rbuf has no byteenable. Leave floating
        .wrdata_to(tilram_rbuf_fetcher_wrdata),
        .wren_to(tilram_rbuf_fetcher_wren)
    );


    // ===================
    // === patram_rbuf ===
    // ===================
    /* patram_rbuf Module Overview
     *
     * After the tilram_rowbuf module finishes gathering tile-data, pattern addresses in those
     *   tile-data entries are used to download pixel values for the current row into this local
     *   RAM.
     * We must store the equivalent of 41 rows of pixel data, or 41*8 = 328 pixels.
     * However, due to how Pattern memory is laid out, as well as due to our 64-bit readdata width,
     *   we will inevitably need to make 41 separate accesses to Pattern RAM, each containing extra
     *   pixel rows we do not need.
     * Each access to Pattern RAM gives us 2 8-pixel-4bpp rows in a target tile (who's base address
     *   is determined by the address stored in tilram_rowbuf).
     */

    // Address to tilram_rbuf (acting as our address buffer)
    logic [5:0] patram_fetcher_addr_abuf; // multiplexed into tilram_rowbuf's address line

    // Permanently attached to indirect_syncwriter/(patram_fetcher)
    logic [5:0]  patram_rbuf_fetcher_wraddr;
    logic [63:0] patram_rbuf_fetcher_wrdata;
    logic        patram_rbuf_fetcher_wren;

    // Note that we must delay the mirror signals until our final readdata comes back
    logic x_mirror, x_mirror_buf1, x_mirror_buf2;
    assign x_mirror = tilram_fetcher_pmxr_rddata[0];
    logic y_mirror_buf1, y_mirror_buf2;

    // patram_rbuf_fetcher_wrdata, but with only x-mirror applied
    logic [63:0] patram_rbuf_fetcher_wrdata_mir_x;
    assign patram_rbuf_fetcher_wrdata_mir_x = {
        // 2nd row mirrored
        patram_rbuf_fetcher_wrdata[35:32],
        patram_rbuf_fetcher_wrdata[39:36],
        patram_rbuf_fetcher_wrdata[43:40],
        patram_rbuf_fetcher_wrdata[47:44],
        patram_rbuf_fetcher_wrdata[51:48],
        patram_rbuf_fetcher_wrdata[55:52],
        patram_rbuf_fetcher_wrdata[59:56],
        patram_rbuf_fetcher_wrdata[63:60],
        // 1st row mirrored (most significant 4-bit chunk becomes least significant)
        patram_rbuf_fetcher_wrdata[3:0],
        patram_rbuf_fetcher_wrdata[7:4],
        patram_rbuf_fetcher_wrdata[11:8],
        patram_rbuf_fetcher_wrdata[15:12],
        patram_rbuf_fetcher_wrdata[19:16],
        patram_rbuf_fetcher_wrdata[23:20],
        patram_rbuf_fetcher_wrdata[27:24],
        patram_rbuf_fetcher_wrdata[31:28]
    };
    // patram_rbuf_fetcher_wrdata, but with only y-mirror applied
    logic [63:0] patram_rbuf_fetcher_wrdata_mir_y;
    assign patram_rbuf_fetcher_wrdata_mir_y = {
        // 1st row mirrored (most significant 4-bit chunk becomes least significant)
        patram_rbuf_fetcher_wrdata[31:28],
        patram_rbuf_fetcher_wrdata[27:24],
        patram_rbuf_fetcher_wrdata[23:20],
        patram_rbuf_fetcher_wrdata[19:16],
        patram_rbuf_fetcher_wrdata[15:12],
        patram_rbuf_fetcher_wrdata[11:8],
        patram_rbuf_fetcher_wrdata[7:4],
        patram_rbuf_fetcher_wrdata[3:0],
        // 2nd row mirrored
        patram_rbuf_fetcher_wrdata[63:60],
        patram_rbuf_fetcher_wrdata[59:56],
        patram_rbuf_fetcher_wrdata[55:52],
        patram_rbuf_fetcher_wrdata[51:48],
        patram_rbuf_fetcher_wrdata[47:44],
        patram_rbuf_fetcher_wrdata[43:40],
        patram_rbuf_fetcher_wrdata[39:36],
        patram_rbuf_fetcher_wrdata[35:32]
    };
    // patram_rbuf_fetcher_wrdata, but with both x and y-mirror applied
    logic [63:0] patram_rbuf_fetcher_wrdata_mir_xy;
    assign patram_rbuf_fetcher_wrdata_mir_xy = {
        // 1st row mirrored (most significant 4-bit chunk becomes least significant)
        patram_rbuf_fetcher_wrdata[3:0],
        patram_rbuf_fetcher_wrdata[7:4],
        patram_rbuf_fetcher_wrdata[11:8],
        patram_rbuf_fetcher_wrdata[15:12],
        patram_rbuf_fetcher_wrdata[19:16],
        patram_rbuf_fetcher_wrdata[23:20],
        patram_rbuf_fetcher_wrdata[27:24],
        patram_rbuf_fetcher_wrdata[31:28],
        // 2nd row mirrored
        patram_rbuf_fetcher_wrdata[35:32],
        patram_rbuf_fetcher_wrdata[39:36],
        patram_rbuf_fetcher_wrdata[43:40],
        patram_rbuf_fetcher_wrdata[47:44],
        patram_rbuf_fetcher_wrdata[51:48],
        patram_rbuf_fetcher_wrdata[55:52],
        patram_rbuf_fetcher_wrdata[59:56],
        patram_rbuf_fetcher_wrdata[63:60]
    };

    // Final write-data to patram_rbuf after any mirror transformations are applied
    logic [63:0] patram_rbuf_fetcher_wrdata_final;
    always_comb begin
        case ({y_mirror_buf2, x_mirror_buf2})
            2'b01: patram_rbuf_fetcher_wrdata_final = patram_rbuf_fetcher_wrdata_mir_x;
            2'b10: patram_rbuf_fetcher_wrdata_final = patram_rbuf_fetcher_wrdata_mir_y;
            2'b11: patram_rbuf_fetcher_wrdata_final = patram_rbuf_fetcher_wrdata_mir_xy;
            default: patram_rbuf_fetcher_wrdata_final = patram_rbuf_fetcher_wrdata;
        endcase
    end
    
    // Permanently attached to pixel-mixer (through some special access logic for scrolling)
    logic [9:0]  patram_rbuf_pmxr_rdaddr;
    // pixelrow[0] toggles between the 1st and 2nd rows (32b each) we buffered in tilram_rbuf
    // tile_addr selects 1 out of 64 (technically 41) tile-slices of pixels
    // pixel_addr[2:0] selects 1 out of the 8 pixels in the chosen tile-slice
    assign patram_rbuf_pmxr_rdaddr = { tile_addr, pixelrow[0], pixel_addr[2:0] };

    logic [3:0]  patram_rbuf_pmxr_rddata;
    
    tileng_rowdata_patram patram_rbuf (
        .address_a(patram_rbuf_fetcher_wraddr),
        .address_b(patram_rbuf_pmxr_rdaddr),
        .clock(clk),
        .data_a(patram_rbuf_fetcher_wrdata_final),
        .data_b('X),         // Read-only port for pixel-mixer
        .wren_a(patram_rbuf_fetcher_wren),
        .wren_b(1'b0),       // Read-only port for pixel-mixer
        .q_a(),              // Port-A is used by patram_fetcher, which only writes (leave unused)
        .q_b(patram_rbuf_pmxr_rddata)
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
    assign pattern_addr_base = tilram_fetcher_pmxr_rddata[15:6];

    // Vertical mirror bit. Used to determine pattern_addr_offset
    logic y_mirror;
    assign y_mirror = tilram_fetcher_pmxr_rddata[1];

    // Given a tile's base address into pattern RAM, which 2/8 rows to copy to our local pattern buf
    logic [1:0] pattern_addr_offset;
    assign pattern_addr_offset = (y_mirror) ? ~(pixelrow[2:1]) : pixelrow[2:1];

    logic [11:0] rddata_abuf;
    assign rddata_abuf = {pattern_addr_base, pattern_addr_offset};

    indirect_sync_writer #(
        .ABUF_ADDR_WIDTH(6),
        .ABUF_NUM_ADDR(44),
        .DATA_WIDTH(64),
        .SRC_ADDR_WIDTH(12),
        .TARG_ADDR_WIDTH(6)
    ) patram_fetcher (
        .clk,
        .rst_n,
        .sync(patram_fetcher_start),
        .done(patram_fetcher_done),
        .addr_abuf(patram_fetcher_addr_abuf), // This is connected to tilram_rbuf_rdaddr during prep
        .rddata_abuf,
        .addr_src(patram_addr),
        .wren_src(), // We only read from Pattern-RAM. This is already taken care of by ppu_logic
        .rddata_src(patram_rddata),
        .addr_targ(patram_rbuf_fetcher_wraddr),
        .wrdata_targ(patram_rbuf_fetcher_wrdata),
        .wren_targ(patram_rbuf_fetcher_wren)
    );


    // =======================
    // === Pixel-Mixer I/O ===
    // =======================
    // In order to ensure the pixel mixer fetches the correct tile palette, we must incorporate our
    //   current scroll value.
    logic [8:0] pmxr_pixel_addr_scrolled;
    logic [5:0] pmxr_tile_addr;
    assign pmxr_pixel_addr_scrolled = pmxr_pixel_addr + (scroll_x & 9'b11111);
    assign pmxr_tile_addr = pmxr_pixel_addr_scrolled[8:3];

    // This read-address port into tilram_rbuf is multiplexed between the patram_fetcher and pmxr.
    assign tilram_rbuf_rdaddr = (state == TILENG_PREP) ? patram_fetcher_addr_abuf : pmxr_tile_addr;

    // This contains valid data with 1-cycle of read latency during the IDLE state
    // The MSBs form a color palette address, the LSBs form the pixel color
    assign pmxr_pixel_data = (enable) ? {tilram_fetcher_pmxr_rddata[5:2], patram_rbuf_pmxr_rddata} :
                                        8'b0;


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
            x_mirror_buf1 <= 1'b0;
            x_mirror_buf2 <= 1'b0;
            y_mirror_buf1 <= 1'b0;
            y_mirror_buf2 <= 1'b0;
        end
        else begin

            // implement x-mirror amd y-mirror signal delay
            x_mirror_buf1 <= x_mirror;
            x_mirror_buf2 <= x_mirror_buf1;
            y_mirror_buf1 <= y_mirror;
            y_mirror_buf2 <= y_mirror_buf1;

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