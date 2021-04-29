/** @file ppu.h
 * @author Joseph Yankel
 * @brief User Library for the FP-GAme PPU
 *
 * @attention Modifications to the PPU will not be accepted during certain busy states managed by
 *   the Kernel. Any functions which attempt to modify PPU data will return -1 if the modification
 *   could not be made. You are encouraged to poll these functions until they return 0 (success) if
 *   you want to ensure your changes are made.
 * @attention Invalid arguments (see the function's documentation) will result in a console warning
 *   and exiting of the program. This is to help you (the user) find bugs and unwanted behaviours.
 */

#ifndef _FP_GAME_PPU_H_
#define _FP_GAME_PPU_H_

#include <stdlib.h>
#include <stdint.h>
#include <sys/types.h>

/* ======================= */
/* === Types and Enums === */
/* ======================= */
/** @brief An enum which specifies a render layer.
 * 
 * These enum entries can be ORd together to form a bitmask. @see ppu_set_layer_enable.
 */
typedef enum {
    LAYER_BG     = 1, ///< Denotes the background tile render layer
    LAYER_FG     = 2, ///< Denotes the foreground tile render layer 
    LAYER_SPR    = 4  ///< Denotes the sprite render layer
} layer_e;

/** @brief Mirror state for graphics */
typedef enum {
    MIRROR_NONE = 0, ///< Pattern is not mirrored
    MIRROR_X    = 1, ///< Pattern is horizontally flipped
    MIRROR_Y    = 2, ///< Pattern is vertically flipped
    MIRROR_XY   = 3  ///< Pattern is both horizontally and vertically flipped
} mirror_e;

/** @brief Rendering priority for sprites */
typedef enum {
    PRIO_IN_BACK   = 0, ///< Sprite apperas behind both background and foreground tile layers.
    PRIO_IN_MIDDLE = 1, ///< Sprite appears in front of background but behind foreground tile layer.
    PRIO_IN_FRONT  = 2  ///< Sprite appears in front of background and foreground tile layers.
} render_prio_e;

/** @brief Address into pattern memory. Generate using @ref ppu_pattern_addr */
typedef unsigned pattern_addr_t;

/** @brief Tile data representation (technically 2B of data) */
typedef uint16_t tile_t;

/** @brief A single 8x8 tiles worth of pattern data (8 rows of 8 pixels at 4bpp) (32B of data) */
typedef struct {
    uint32_t pxrow[8]; ///< 8 4b pixels take up one uint32_t and make up 1 row. We have 8 rows.
} pattern_t;

/** @brief A palette which contains 15 colors */
typedef struct {
    uint32_t color[15]; ///< Array of 24-bit colors (last byte of 32-bit entry is ignored)
} palette_t;

/** @brief A sprite */
typedef struct {
    pattern_addr_t pattern_addr; ///< Address of this sprite's starting pattern in Pattern RAM.
    unsigned palette_id;    ///< Palette to use for this sprite.
    mirror_e mirror;        ///< Graphics mirror functionality for this sprite.
    render_prio_e prio;     ///< Render this sprite above, in the middle, or behind other layers.
    uint16_t x;             ///< x coordinate relative to top-left of screen for sprite [0, 319].
    uint16_t y;             ///< y coordinate relative to top-left of screen for sprite [0, 239].
    uint8_t height;         ///< Height of sprite in terms of 8x8-pixel tiles. Legal values: [1, 4]
    uint8_t width;          ///< Width of sprite in terms of 8x8-pixel tiles. Legal values: [1, 4]
} sprite_t;


/* ========================= */
/* === PPU Main Controls === */
/* ========================= */
/** @brief Enable the PPU
 *
 * Attempts to lock PPU access to this process. If successful, only this process will be able to
 *   write to the PPU.
 *
 * Fails if the PPU is already owned by another process.
 *
 * The caller of this function must call ppu_disable before program exit to prevent resource leaks.
 *
 * @return 0 on success; -1 on error
 */
int ppu_enable(void);

/** @brief Disable the PPU
 *
 * Releases the lock on the PPU. Other processes will be able to reserve access to the PPU.
 *
 * It is illegal to call this function if the PPU is not currently enabled and owned by the calling
 * process.
 */
void ppu_disable(void);

/** @brief Request for the current frame changes to be send to the PPU on the next available frame
 *
 * Any previous calls to ppu_set_[...] functions are guaranteed to take effect after this function
 *   returns successfully.
 *
 * If you want to ensure your frame gets sent out to the PPU, and also want to synchronize to the
 *   PPU's internal 60FPS timing, keep polling this function until 0 (success) is returned.
 *
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_update(void);

/** @brief Write directly to the VRAM buffer 
 *
 * @attention This gives a lower-level access to the VRAM buffer! See the higher-level write
 *   functions such as the various ppu_write_tiles functions, @ref ppu_write_sprites,
 *   @ref ppu_write_pattern, and @ref ppu_write_palette.
 *
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param buf Pointer to a buffer to write to the VRAM.
 * @param len Size of buf in bytes.
 * @param offset Byte offset into VRAM.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_write_vram(const void *buf, size_t len, off_t offset);


/* =========================== */
/* === PPU Data Generators === */
/* =========================== */
/** @brief Generates a pattern_addr_t using a pattern_id, and relative (x, y) position
 *
 * Pattern RAM is organized into blocks of 32x32-pixel chunks (or 4x4 8x8-pixel tile groups).
 * @image html pattern_ram_organization.svg
 * Note each small square tile in the diagram above represents an 8 pixel by 8 pixel tile. There are
 *   16 such tiles per tile group.
 *
 * @p pattern_id selects which of these tile groups to write to.
 *   ( @p x, @p y ) indicates a position within this 16 tile group with the origin (0, 0) at the top
 *   left.
 *
 * @param pattern_id Index into Pattern RAM selecting a tile group. Range [0, 63].
 * @param x Within the selected tile group, horizontal tile offset. Range [0, 3].
 * @param y Within the selected tile group, vertical tile offset. Range [0, 3].
 * @returns A pattern_addr_t representing the address into Pattern RAM formed by the arguments.
 */
pattern_addr_t ppu_pattern_addr (unsigned pattern_id, unsigned x, unsigned y);

/** @brief Generate a tile data for use with the ppu_write_tile functions
 *
 * @param pattern_addr The address of this tile's pattern in Pattern RAM (see @ref ppu_pattern_addr)
 * @param palette_id The numerical id of the palette (location in Palette RAM) this tile will use.
 *                   This must be within range [0, 16]. The final palette comes from the background
 *                   layer palette section of Palette RAM if this tile is applied to the background
 *                   tile layer, and similarly for forground palettes.
 * @param mirror     Mirror state for this tile's pattern.
 * @return           A tile_t representing the tile data formed by the inputs.
 */
tile_t ppu_make_tile(pattern_addr_t pattern_addr, unsigned palette_id, mirror_e mirror);

/** @brief Generate a sprite data for use with the ppu_write_sprites function
 *
 * Importantly, the sprite's position is defaulted to (0, 0).
 *
 * @param sprite Pointer to an empty sprite_t struct you want to initialize.
 * @param pattern_addr The address into Pattern RAM where this sprite starts. Recommended to
 *                     generate using @ref ppu_pattern_addr.
 * @param width Horizontal width of sprite in tiles. Can take values in [1, 4].
 * @param height Vertical height of sprite in tiles. Can take values in [1, 4].
 * @param palette_id Palette from the sprites section of Palette RAM to use. Must be within [0, 31].
 * @param prio Render priority for this sprite.
 * @param mirror Horizontal/Vertical mirror setting for this sprite.
 */
void ppu_make_sprite(sprite_t *sprite, pattern_addr_t pattern_addr, unsigned width, unsigned height,
                     unsigned palette_id, render_prio_e prio, mirror_e mirror);

/** @brief Loads tile-data from a file into an linear array of tile_t
 *
 * The text file contains tile_t entries specified in the following format:
 *   * An entry is formatted like (XXX,X,X), where X is a hex number (0-F).
 *   * The first three hex numbers are the pattern ID for this tile. It ranges from 000 to 3FF.
 *   * The second entry is the palette ID to use for this tile. It ranges from 0 to F.
 *   * The last entry are the tile mirroring bits. This value ranges from 0 to 3, where:
 *     * 0 -> No mirror
 *     * 1 -> Horizontal Mirroring
 *     * 2 -> Vertical Mirroring
 *     * 3 -> Both Horizontal AND Vertical Mirroring 
 *   * Each entry is separated either by a space or by a newline.
 *
 * @param tilemap Array of tile_t to load into.
 * @param len Number of tiles to copy to @p tilemap.
 * @param file Path of the text file to open and read from.
 */
void ppu_load_tilemap(tile_t *tilemap, unsigned len, char *file);

/** @brief Loads width*height-tile graphics into @p pattern from @p file
 *
 * @p file must be a .pattern text file, height * 8 lines, each with width * 8 hex chars: 0-F. Each
 *    hex char represents a pixel's color for any palette. 0 is always transparent, 1-F correspond
 *    to the 15 available colors in a palette. This format is best exported from
 *    art_tools/c_to_pattern.py.
 *
 * Example (width = height = 8):
 *
 * 112233445
 *
 * F00000005
 *
 * F00000006
 *
 * E00000006
 *
 * E00000007
 *
 * D00000007
 *
 * D00000008
 *
 * CCBBAA998
 *
 * A test file with the above text represents a multi-colored box outline with transparent center.
 *
 * @param pattern Pattern instance to copy the pixel data from @p file to.
 * @param file File path of the text file to copy pixel data from.
 * @param width Number of 8x8 tile-patterns wide. Supports 1, 2, 3, or 4.
 * @param height Number of 8x8 tile-patterns tall. Supports 1, 2, 3, or 4.
 */
void ppu_load_pattern(pattern_t *pattern, char *file, unsigned width, unsigned height);

/** @brief Loads a color palette from @p file into @p palette
 *
 * @p file must be a simple text file, containing 15 lines, each with a 24-bit hex color.
 *    For example, each line has something of the form: FF0000
 *    The example above is a hex representation for the color RED.
 *
 * @param palette Palette instance to copy the color data from @p file to.
 * @param file File path of the text file to copy color data from.
 */
void ppu_load_palette(palette_t *palette, char *file);

/* =========================== */
/* === PPU Write Functions === */
/* =========================== */
/** @brief Writes an array to a horizontal segment of tiles
 *
 * This function copies a buffer of length len tiles into the Tile RAM overwriting count tiles
 *   starting at ( @p x_i, @p y_i ) and moving horizontally. If overwriting count tiles would exceed
 *   the boundaries of the logical screen (63, @p y_i ), this function will automatically wrap
 *   around to the start of the logical screen (0, @p y_i ).
 * 
 * If len is lower than count, then this function repeats/tiles the given tiles buffer.
 *
 * This function is more efficient than ppu_write_tiles_vertical. So if writing a rectangular block
 *   of tiles on the screen, prefer to call this function as the inner loop (make the row, @p y_i be
 *   the outer loop variable).
 *
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param tiles Buffer of tile data to write to Tile RAM.
 * @param len Length of the tiles buffer. @p len will be clamped to 64 if len > 64.
 * @param layer Must be either LAYER_FG or LAYER_BG, depending on which tile RAM section to write.
 * @param x_i Horizontal position of the first tile to write. Must be in the range [0, 63]
 * @param y_i Vertical position of the first tile to write. Must be in the range [0, 63]
 * @param count The number of tiles to overwrite (horizontally) in Tile RAM. @p count will be set to
 *              64 if count > 64.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_write_tiles_horizontal(tile_t *tiles, unsigned len, layer_e layer, unsigned x_i,
                               unsigned y_i, unsigned count);

/** @brief Writes an array to a vertical segment of tiles
 *
 * This function copies a buffer of length len tiles into the Tile RAM overwriting count tiles
 *   starting at ( @p x_i, @p y_i ) and moving vertically. If overwriting count tiles would exceed
 *   the boundaries of the logical screen ( @p x_y, 63), this function will automatically wrap
 *   around to the start of the logical screen ( @p x_i, 0).
 *
 * If len is lower than count, then this function repeats/tiles the given tiles buffer.
 *
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param tiles Buffer of tile data to write to Tile RAM.
 * @param len Length of the tiles buffer. @p len will be clamped to 64 if len > 64.
 * @param layer Must be either LAYER_FG or LAYER_BG, depending on which tile RAM section to write.
 * @param x_i Horizontal position of the first tile to write. Must be in the range [0, 63].
 * @param y_i Vertical position of the first tile to write. Must be in the range [0, 63].
 * @param count The number of tiles to overwrite (vertically) in Tile RAM. @p count will be set to
 *              64 if count > 64.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_write_tiles_vertical(tile_t *tiles, unsigned len, layer_e layer, unsigned x_i, unsigned y_i,
                             unsigned count);

/** @brief Writes pattern_t patterns (8x8-pixel tiles) to a specified location in Pattern RAM
 *
 * @note As a reminder, pattern_addr points to a tile chunk and also a specific tile at (x_i, y_i)
 *       within.
 *
 * Within the current tile chunk pointed to by pattern_addr, a subset of @p width pattern_t by
 *   @p height pattern_t is formed.
 *
 * pattern_t tile-patterns (8x8-pixel tiles) from @p patterns are written sequentially by rows of
 *   @p width until @p height rows have been written.
 *
 * The example diagrams below demonstrate the effect of this function with a variable width/height
 *   and pattern_addr of 0:
 * @image html ppu_write_patterns_ex0.svg
 * @image html ppu_write_patterns_ex1.svg
 *
 * @warning Note, however that if the subset indicated by width, height, x_i, y_i would extend
 *          beyond a 16x16 tile-group boundary, this function will give a warning and abort the
 *          program. For example, you are not allowed to write a 3x3-tile pattern starting at (2,3).
 * @image html ppu_write_patterns_ex2.svg
 * Another illegal example for a 2x2-tile pattern starting at (3, 0):
 * @image html ppu_write_patterns_ex3.svg
 *
 * @warning It is the user's responsibility to ensure @p patterns has length @p width * @p height
 *          (in terms of pattern_t).
 * 
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param pattern The buffer of pattern_t tiles. @p patterns must have @p width * @p height
 *                total pattern_t. Create your buffer so that the pattern_t tiles occur row by row
 *                sequentially.
 * @param width The width (in 8x8-pixel tiles) of @p patterns. Range [1, 4]
 * @param height The height (in 8x8-pixel tiles) of @p patterns. Range [1, 4]
 * @param pattern_addr The pattern address to start at.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_write_pattern(pattern_t *pattern, unsigned width, unsigned height,
                      pattern_addr_t pattern_addr);

/** @brief Overwrites a palette in Palette RAM
 *
 * Overwrites a single @p palette in Palette RAM at @p palette_id and @p layer_id
 *
 * Recall that Palette RAM is organized into three segments. @p layer_id selects one of these
 *   layers:
 *   0:      Background Palettes. 16 Palettes
 *   1:      Foreground Palettes. 16 Palettes
 *   (Else): Sprite Palettes.     32 Palettes
 *
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param palette A pointer to a palette data struct that we should write to Palette RAM.
 * @param layer_id The target section of Palette RAM to start copying the @p palette to.
 * @param palette_id The id of the palette to overwrite within the given layer. This must be within
 *                   bounds of the palette layer section indicated by @p layer_id.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_write_palette(palette_t *palette, layer_e layer_id, unsigned palette_id);

/** @brief Overwrites one or more sprite data entries in Sprite RAM
 * 
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param sprites A pointer to an array of sprite data entries to submit to Sprite RAM.
 * @param len Length of @p sprites array.
 * @param sprite_id_i The starting index of the first sprite to overwrite in Sprite RAM. This number
 *                    must fall in range [0, 63 - @p len ].
 * @return 0 on success; -1 if PPU busy
 */
int ppu_write_sprites(sprite_t *sprites, unsigned len, unsigned sprite_id_i);

/** @brief Set the universal background color of the PPU
 *
 * The universal background color is the color displayed when all PPU render layers are transparent.
 *
 * This function will set this color to be displayed at the next @ref ppu_update().
 *
 * @remark Any higher-order bits [31:24] in @p color will be ignored!
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param color 32-bit color holding a 24-bit RRGGBB hex color value. For example, 0xFF0000 for red.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_set_bgcolor(unsigned color);

/** @brief Set pixel scroll of the background or foreground tile layer
 *
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param tile_layer Either LAYER_BG or LAYER_FG. LAYER_SPR doesn't support layer scrolling.
 * @param scroll_x Horizontal pixel scroll. Values must be [0, 511].
 * @param scroll_y Vertical pixel scroll. Values must be [0, 511].
 * @return 0 on success; -1 if PPU busy
 */
int ppu_set_scroll(layer_e tile_layer, unsigned scroll_x, unsigned scroll_y);

/** @brief Enable or disable one or more of the three PPU render layers using a bit-mask
 *
 * The enable mask has three bits which enable or disable the PPU render layers as follows:
 * Bit 0: Enable (1) or disable (0) the background tile layer
 * Bit 1: Enable (1) or disable (0) the foreground tile layer
 * Bit 2: Enable (1) or disable (0) the sprite layer
 * To generate the enable_mask, use an OR of the layer_e options. For example, to enable both tile
 *   layers and disable the sprite layer set enable_mask = BG | FG.
 *
 * Call this function before a @ref ppu_update() to ensure the layer will be enabled on the next
 *   frame.
 *
 * @remark Any higher-order bits in enable_mask not specified above will be ignored!
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param enable_mask Bit-mask used to enable/disable PPU rendering layers.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_set_layer_enable(unsigned enable_mask);

#endif /* _FP_GAME_PPU_H_ */