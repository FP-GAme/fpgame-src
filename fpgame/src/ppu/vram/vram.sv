/* vram.sv
 *
 * Implements the PPU's 4-segment dual-port double-buffered VRAM structure.
 */

/* Tile RAM Contents and Layout
 * There are 64*64 = 4096 total tiles in a single layer, though only 40x30 can be shown on screen at
 *   once (41+31 when you consider scrolling).
 * There is a foreground and background layer, which adds up to a total of 8192 tiles.
 * In Tile RAM, each one of these tiles is represented by 16-bits (2B). In order from MSB->LSB:
 * 10 address bits to Pattern RAM - Used to tell where the 8x8 pattern is in Pattern RAM
 * 4 palette bits - Used to tell what color palette this tile uses.
 *                  Acts as an address to the BG/FG section in Palette RAM, depending on FG/BG tile.
 * 2 mirroring bits - Should the tile's graphics be flipped on none, y, x, or both axis on screen?
 *                    0th bit corresponds to x mirror, 1st bit corresponds to y mirror.
 *
 * Assuming a 2B access width (word-addressable), the layout in memory is as follows:
 * The first background tile at row 0 and column 0, tile(0,0), is held at memory address 0x1000.
 * The first foreground tile, tile(0,0), is held at memory address 0x1000.
 * For now, let's focus on the 64x64 background tiles (since the foreground tiles have the same
 *   layout, just with the MSB set to 1 instead of 0):
 * The memory layout is row by column. So 64 tiles in the 0th row are placed in memory, and then
 *   the next 64 tiles in the 1st row are placed just after... and so on.
 *
 * Example:
 * Tile(0,   0), - start of the 0th row
 * Tile(1,   0),
 *     ...     , 
 * Tile(63,  0), - end of the 0th row
 * Tile(0,   1), - start of the 1st row
 * Tile(1,   1),
 *     ...     , 
 * Tile(1,   1), - end of the 1st row
 *     ...     , 
 *     ...     , 
 *     ...     , 
 * Tile(0,  63), - start of the 63rd row
 *     ...     , 
 * Tile(63,  63), - end of the 63rd row and background tile memory
 * Repeat this sequence for foreground tile memory.
 */

/* Pattern RAM Contents and Layout
 * Pattern RAM contains 1024 total 8x8 pixel tiles, each pixel has 4 bits for determining its color.
 * Tiles are laid out in sequential order, starting from row 0 of tile 0 up to row 7 of tile 0,
 *   after which, the next tile's pixel rows are placed.
 *
 * With 64-bit access in mind, each address accesses 2 rows of a tile (4b/px * 8px/row * 2rows =
 *   64b). This means that in order to access a new tile, you must increment the address 4 times.
 */

module vram (
    input logic clk,
    input logic rst_n,

    // these following interfaces are inputs (see src modport in vram_if)
    vram_if.src vram_ifP_src, // PPU uses vram_P
    vram_if.src vram_ifC_src  // CPU uses vram_C
);

    // PPU-Facing VRAM
    vram_sub vram_P (
        .clk,
        .i_src(vram_ifP_src)
    );

    // CPU-Facing VRAM
    vram_sub vram_C (
        .clk,
        .i_src(vram_ifC_src)
    );

endmodule : vram
