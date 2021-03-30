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
 * If enable == 0, then this PPU will still do everything it normally does, but it will always
 *   output 0s when asked for pixel values. Effectively rendering the layer transparent.
 */

module tile_engine #(
    parameter FG = 0; // Set to 0 to address BG Tile RAM; 1 to address FG Tile RAM.
) (
    input  logic clk,
    input  logic rst_n,

    // From ppu_logic (and technically hdmi_video_output)
    input  logic [8:0]  row,

    // From Double-Buffered Control Registers
    input  logic [31:0] scroll,
    input  logic        enable,

    // from/to Pixel Mixer
    input  logic [8:0] pixel_addr,
    output logic [7:0] pixel_data,
    output logic       done
);

    logic [8:0] scroll_x;
    logic [5:0] tile_scroll_x;
    logic [2:0] pixel_scroll_x;
    assign scroll_x = scroll[8:0];
    assign tile_scroll_x = scroll_x[8:3];
    assign pixel_scroll_x = scroll_x[2:0];

    logic [8:0] scroll_y;
    logic [5:0] tile_scroll_y;
    logic [2:0] pixel_scroll_y;
    assign scroll_y = scroll[24:16];
    assign tile_scroll_y = scroll_y[8:3];
    assign pixel_scroll_y = scroll_y[2:0];

    /* Tile RAM Base Address Calculation
     * Since we interact with a 64-bit bus, we must read 4 2B tiles at a time. Thus, we will be
     *   addressing groups of 4 tiles: A single row of Tile RAM will have 16 "tile chunks".
     * Since we need a row of 40 tiles, but we can only address groups of 4, we will inevitably need
     *   to read 44 tiles, and choose the 40 to access based on scrolling.
     * To calculate the base address:
     *   1. First index into the first or second half of VRAM using FG.
     *   2. Then, index into one of 64 tile rows using tile_scroll_y + row (overflow is okay).
     *   3. Then, using the 4MSBs of tile_scroll_x, pick 1 out of the 16 tile chunks to start with.
     *      Note, we will use the 2 LSBs of tile_scroll_x later to pick through which of the 4 tiles
     *        in the first chunk to actually display.
    */
    logic [10:0] tile_base_addr;
    assign tile_base_addr = {FG, tile_scroll_y + row, tile_scroll_x[5:2]};

    // We will tell the sync writer to start at tile_base_addr and copy 11/16 tile chunks.
    sync_writer tiledata_reader #(
        DATA_WIDTH = 64,
        ADDR_WIDTH = 4,
        MAX_ADDR = 11
    )(
        .clk,
        .rst_n,
        .sync(), // TODO: Decide on how/when to signal to start.
        .done(), // TODO: Maybe need this, maybe not.
        .addr_from(), // TODO: Attach to the 64-bit address port of tile ram
        .wren_from(), // TODO: attach to the wren port of tile ram
        .rddata_from(), // TODO: Attach to the rddata port of tile ram
        .addr_to(), // TODO: Attach to the addr port of 
    );
    // TODO: Need to do some funny wiring stuff where we take the output address from addr_from and add it to the tile_scroll_x value in tile_base_addr, allowing it to overflow with truncation.
    // TODO: This value will be sent to the Tile-RAM. The addr_to will simply attach to the tileng_rowdata_tilram buffer.

    tileng_rowdata_tilram trt (
        .address_a(); // TODO: Permanently attached to syncwriter (no funny wiring business here)
        .address_b(); // TODO, this will tie into something that switches between our output and the address controller of pattern ram.
        .clock(clk);
        .data_a();    // TODO: Permanently attached to syncwriter
        .data_b('X);  // Ignored since nothing writes to this port
        .wren_a();
        .wren_b(1'b0); // Disable writes to this port.
        .q_a();        // Left empty since nothing reads from the 64-bit port.
        .q_b();        // TODO Attach to something that switches between output and the address controller of pattern ram depending on state
    );

    // TODO: FSM goes like this:
    // 1. Idling around. Waiting for start signal
    // Start signal received, transition to Tile Data Read
    // 2. Tile Data Read (idling for around 11+2 cycles)
    // Done signal from sync_writer. Transition to Pattern Data read
    // 3. Pattern data read. Probably need to use a new FSM or make it part of this FSM.
    // Once that finishes (either through a done-signal or just a new state in this FSM, sit around for the next buffer-swap signal)
    // Note, the Pixel Mixer will automatically read when all pixel engines are done.

    //TODO To do pattern data read,

endmodule : tile_engine