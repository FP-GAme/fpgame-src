/** @file ppu.c
 * @author Joseph Yankel
 * @brief PPU library implementation
 */


/* ================ */
/* === Includes === */
/* ================ */
#include <fp-game/ppu.h>
#include <fp-game/drv_ppu.h>

#include <stdlib.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>

#include <noway.h>
#include <errno.h>
#include <assert.h>
#include <string.h>


/* ================== */
/* === Anti-Magic === */
/* ================== */
#define TILELAYER_MAX_PALETTES 16 ///< Maximum palettes for tile layers (as opposed to sprite layer)
#define SPRLAYER_MAX_PALETTES 32  ///< Maximum palettes for sprite layer (as opposed to tile layers)
#define PATTERN_MAXADDR 1023      ///< Maximum pattern_addr_t value
#define MIRROR_MAXVAL 3           ///< Maximum allowable value for mirror_e
#define SPRITE_MAXCOUNT 64        ///< Maximum supported sprites
#define COLOR_24MASK 0xFFFFFF     ///< 24-bit color mask
#define LAYER_ENMASK 0x7          ///< Enable Mask for layer_e
#define TILELAYER_WIDTH 64        ///< Width (in tiles) of the tile layer
#define TILELAYER_HEIGHT 64       ///< Height (in tiles) of the tile layer
#define VRAM_PATTERNOFFSET 0x4000 ///< Byte offset of Pattern RAM in VRAM
#define VRAM_PALETTEOFFSET 0xC000 ///< Byte offset of Palette RAM in VRAM
#define VRAM_SPRITESOFFSET 0xD000 ///< Byte offset of Sprite RAM in VRAM
#define PALETTERAM_BGOFFSET 0     ///< Byte offset from start of Palette RAM to BG section
#define PALETTERAM_FGOFFSET 0x400 ///< Byte offset from start of Palette RAM to FG section
#define PALETTERAM_SPROFFSET 0x800///< Byte offset from start of Palette RAM to SPR section
#define PALETTERAM_SPRITEMAX 32   ///< Maximum number of palettes for sprites to access
#define PALETTERAM_TILEMAX 16     ///< Maximum number of palettes for a tile layer to access
#define SPRRAM_EXTRAOFFSET 0x100  ///< Byte offset of the extra data in Sprite RAM
#define TILEPATTERN_BSIZE 32      ///< Size (in Bytes) of a single pattern_t (tile-pattern)
#define TILEPATTERN_HEIGHT 8      ///< Height in pixel rows of a single tile pattern (8x8 tile)
#define TILERAM_FGOFFSET 0x2000   ///< Byte offset for foreground tile layer within Tile RAM
#define TILEDATA_BSIZE 2          ///< Size of tile data in bytes
#define PALETTE15_BSIZE 60        ///< Size of 15 colors (not counting the transparent color)
#define PALETTE16_BSIZE 64        ///< Size of 16 colors (technically a full palette)
#define SPRITE_BSIZE 4            ///< Size of sprite data in bytes
#define SPRITE_MAXWIDTH 4
#define SPRITE_MAXWIDTH 4


/* ========================= */
/* === Helper Prototypes === */
/* ========================= */
unsigned unsigned_min(unsigned a, unsigned b);


/* ========================= */
/* === PPU Main Controls === */
/* ========================= */
/** @brief The file descriptor for the PPU device file. */
static int ppu_fd = -1;

int ppu_enable(void)
{
    nowaymsg(ppu_fd != -1, "PPU already enabled by this process!");

    if ((ppu_fd = open(PPU_DEV_FILE, O_WRONLY)) < 0)
    {
        assert(errno == EBUSY);

        // FP-GAme PPU could not be acquired due to PPU being busy. Another process already has the
        //   PPU access lock.

        ppu_fd = -1; // reset ppu_fd for the next time this function is called
        return -1;
    }

    return 0;
}

void ppu_disable(void)
{
    nowaymsg(ppu_fd == -1, "PPU already disabled or not owned by this process!");

    close(ppu_fd);

    ppu_fd = -1;
}

int ppu_update(void)
{
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");

    if (ioctl(ppu_fd, IOCTL_PPU_UPDATE) < 0)
    {
        assert(errno == EBUSY); // Otherwise, it is an EINVAL, which is OUR fault.

        return -1;
    }

    return 0;
}

int ppu_write_vram(const void *buf, size_t len, off_t offset)
{
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");

    if (pwrite(ppu_fd, buf, len, offset) != (ssize_t)len) {
        assert(errno == EINVAL || errno == EBUSY); // Potentially nasty programming error (EFAULT)

        nowaymsg(errno == EINVAL, "PPU vram write goes out of VRAM bounds!");

        return -1; // In this case, PPU is busy (errno == EBUSY)
    }

    return 0;
}


/* =========================== */
/* === PPU Data Generators === */
/* =========================== */
pattern_addr_t ppu_pattern_addr (unsigned x, unsigned y)
{
    nowaymsg(x > 31, "Argument out of range!");
    nowaymsg(y > 31, "Argument out of range!");

    return (y << 5) | x;
}

tile_t ppu_make_tile(pattern_addr_t pattern_addr, unsigned palette_id, mirror_e mirror)
{
    nowaymsg(pattern_addr > PATTERN_MAXADDR, "Pattern address malformed!");
    nowaymsg(palette_id >= TILELAYER_MAX_PALETTES, "Palette ID out of range!");
    nowaymsg(mirror > MIRROR_MAXVAL, "Mirror argument malformed!");

    return (pattern_addr << 6) | (palette_id << 2) | mirror;
}

void ppu_load_tilemap(tile_t *tilemap, unsigned len, const char *file)
{
    FILE *fp;
    int result;
    uint32_t pattern_addr; // Pattern address
    uint32_t palette_id;   // Palette ID reference
    unsigned mirror;       // Mirror bits
    unsigned count;        // Tile data written so far
    tile_t tiledata;

    nowaymsg(tilemap == NULL, "Tile array is NULL!");
    if (len == 0) return;

    fp = fopen(file, "r");
    nowaymsg(fp == NULL, strerror(errno));

    count = 0;
    do {
        // Reads the format (XXX,X,X) into (patter_addr, palette_id, mirror)
        result = fscanf(fp, "(%3X,%1X,%1X) ", &pattern_addr, &palette_id, &mirror);
        tiledata = ppu_make_tile(pattern_addr, palette_id, mirror);
        tilemap[count] = tiledata;
        count++;
    } while(result != EOF && count < len);

    result = fclose(fp);
    nowaymsg(result == EOF, strerror(errno));
}

void ppu_load_pattern(pattern_t *pattern, const char *file, unsigned width, unsigned height)
{
    FILE *fp;
    int result;
    uint32_t row_pattern;

    nowaymsg(pattern == NULL, "Tile array is NULL!");

    fp = fopen(file, "r");
    nowaymsg(fp == NULL, strerror(errno));

    for (unsigned tile = 0; tile < height; tile++)
    {
        for (unsigned row = 0; row < TILEPATTERN_HEIGHT; row++)
        {
            for (unsigned pxrow = 0; pxrow < width; pxrow++)
            {
                // Read the nibbles for this pixel (each corresponds to a color in the 15-color
                //   palette, 1 is the first color, F is the last, 0 is transparent).
                if (pxrow == width - 1)
                {
                    // Grab a set of 8 pixels and consume the newline
                    result = fscanf(fp, "%8X\n", &row_pattern);
                }
                else
                {
                    // Grab a set of 8 pixels
                    result = fscanf(fp, "%8X", &row_pattern);
                }

                // ensure result was valid
                nowaymsg(result != 1, strerror(errno));

                // Source txt files have reversed nibble ordering (for ease of use) (per each 4B).
                // We need to reverse them back:
                row_pattern = ((row_pattern & 0x0F0F0F0F) << 4) | ((row_pattern & 0xF0F0F0F0) >> 4);
                row_pattern = ((row_pattern & 0x00FF00FF) << 8) | ((row_pattern & 0xFF00FF00) >> 8);
                row_pattern = ((row_pattern & 0x0000FFFF) << 16) | ((row_pattern & 0xFFFF0000) >> 16);
                // Credit to https://stackoverflow.com/questions/58716959/reversing-the-nibbles

                pattern[pxrow + tile * height].pxrow[row] = row_pattern;
            }
        }
    }
    result = fclose(fp);
}

void ppu_load_palette(palette_t *palette, const char *file)
{
    FILE *fp;
    int result;
    uint32_t color;
    unsigned count; // Colors written so far

    nowaymsg(palette == NULL, "Palette is NULL!");

    fp = fopen(file, "r");
    nowaymsg(fp == NULL, strerror(errno));

    count = 0;
    do {
        result = fscanf(fp, "%06X\n", &color);

        // Ignore the first color (always transparent) of the palette:
        if (count > 0) palette->color[count - 1] = color;
        count++;
    } while(result != EOF && count < 16); // Read until end of file or 15 colors

    if (result == -1) perror("Sad life: ");

    result = fclose(fp);
    nowaymsg(result == EOF, strerror(errno));
}


/* =========================== */
/* === PPU Write Functions === */
/* =========================== */
int ppu_write_tiles_horizontal(tile_t *tiles, unsigned len, layer_e layer, unsigned x_i,
                               unsigned y_i, unsigned count)
{
    // Catch input errors and tell the user
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");
    nowaymsg(x_i >= TILELAYER_WIDTH, "Initial write position out of bounds!");
    nowaymsg(y_i >= TILELAYER_HEIGHT, "Initial write position out of bounds!");
    nowaymsg(layer != LAYER_BG && layer != LAYER_FG, "Incorrect layer to write tiles to!");
    nowaymsg(tiles == NULL, "Tile array is NULL!");

    // Catch case where nothing should occur
    if (count == 0 || len == 0) return 0;

    // Clamp len and count to the width of the tile layer. It makes no sense to overwrite more than
    //   a full layer at once.
    count = (count > TILELAYER_WIDTH) ? TILELAYER_WIDTH : count;
    len = (len > TILELAYER_WIDTH) ? TILELAYER_WIDTH : len;

    // If len < count, we need to repeat the sequence of tiles given by "tiles".
    // To do this, construct a write buffer of length (len) which takes into account these repeats.
    unsigned tiles_written = 0; // Keep track of how many tiles we have written so far.
    tile_t *write_tiles;       // Buffer of tiles to write, taking into account tile repeat/loop.

    nowaymsg((write_tiles = malloc(sizeof(tile_t) * count)) == NULL, "Malloc failed!");
    for (unsigned i = 0; i < count; i++)
    {
        write_tiles[i] = tiles[tiles_written];

        // Repeat tile sequence if we have run through all tiles in "tiles".
        tiles_written = (tiles_written == len - 1) ? 0 : tiles_written + 1;
    }

    // We split the tile writing operation into two writes:
    //   1. Write from x_i until either the end of the row, or until we've written count tiles.
    //   2. If we have reached the end of the row, but haven't written count tiles in total, we must
    //      continue writing tiles by wrapping around to the start of the current row.

    // Determine start byte address, offset from the start of Tile-RAM
    unsigned tile_layer_offset = (layer == LAYER_FG) ? TILERAM_FGOFFSET : 0;

    // Byte-address within the BG or FG section of RAM to write to.
    // (64 tiles/row * y_i rows + x_i tiles) * 2B per tile. Note: No offset from VRAM start
    unsigned start_addr = tile_layer_offset + (y_i * TILELAYER_HEIGHT + x_i) * TILEDATA_BSIZE;

    // --- 1st iteration ---
    // How many tiles to write for this writing iteration.
    // Initially, only write up to the end of the current row.
    unsigned tiles_towrite = unsigned_min(TILELAYER_WIDTH - x_i, count);

    // How many bytes to write for this writing iteration.
    unsigned bytes_towrite = tiles_towrite * TILEDATA_BSIZE;

    if (pwrite(ppu_fd, write_tiles, bytes_towrite, start_addr) != (ssize_t)bytes_towrite)
    {
        assert(errno == EBUSY);

        return -1; // In this case, PPU is busy (errno == EBUSY)
    }
    tiles_written = tiles_towrite;

    if ( (tiles_towrite = count - tiles_written) == 0)
    {
        free(write_tiles);

        return 0;
    }

    // --- 2nd iteration ---
    bytes_towrite = tiles_towrite * TILEDATA_BSIZE;

    // Wrap around to the start of the current row
    start_addr = tile_layer_offset + (y_i * TILELAYER_HEIGHT) * TILEDATA_BSIZE;

    if (pwrite(ppu_fd, &write_tiles[tiles_written], bytes_towrite, start_addr) != (ssize_t)bytes_towrite)
    {
        assert(errno == EBUSY);

        return -1; // In this case, PPU is busy (errno == EBUSY)
    }
    assert(count - (tiles_written + tiles_towrite) == 0); // No more tiles left to write

    free(write_tiles);

    return 0;
}

int ppu_write_tiles_vertical(tile_t *tiles, unsigned len, layer_e layer, unsigned x_i, unsigned y_i,
                             unsigned count)
{
    unsigned i;            // Generic reusable loop iterator
    unsigned start_addr;   // Actual Byte-address in VRAM to write to.
    unsigned towrite;      // How many tiles to write for this writing iteration.
    unsigned written;      // Keep track of how many tiles we have written so far.
    tile_t *write_tiles;   // Buffer of tiles to write, taking into account tile repeat/loop.
    unsigned tile_layer_offset;

    // Catch input errors and tell the user
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");
    nowaymsg(x_i >= TILELAYER_WIDTH, "Initial write position out of bounds!");
    nowaymsg(y_i >= TILELAYER_HEIGHT, "Initial write position out of bounds!");
    nowaymsg(tiles == NULL, "Tile array is NULL!");

    // Catch case where nothing should occur
    if (count == 0 || len == 0) return 0;

    // Clamp len and count to the width of the tile layer. It makes no sense to overwrite more than
    //   a full layer at once.
    count = (count > TILELAYER_HEIGHT) ? TILELAYER_HEIGHT : count;
    len = (len > TILELAYER_HEIGHT) ? TILELAYER_HEIGHT : len;

    // We split the tile writing operation into two writes:
    //   1. Write from y_i until either the end of the column, or until we've written count tiles.
    //   2. If we have reached the end of the column, but haven't written count tiles in total, we
    //      must continue writing tiles by wrapping around to the start of the current row.

    // Also importantly, if len < count, we need to repeat the sequence of tiles given by "tiles".
    // To do this, construct a write buffer of length (len) which takes into account repeats.
    nowaymsg((write_tiles = malloc(sizeof(tile_t) * count)) == NULL, "Malloc failed!");
    written = 0; // Keep track of our place in tiles array.
    for (i = 0; i < count; i++)
    {
        write_tiles[i] = tiles[written];

        // Repeat tile sequence if we have run through all tiles in "tiles".
        written = (written == len - 1) ? 0 : written + 1;
    }

    tile_layer_offset = (layer == LAYER_FG) ? TILERAM_FGOFFSET : 0;

    // (64 tiles/row * y_i rows + x_i tiles) * 2B per tile.
    start_addr = tile_layer_offset + ((y_i << 6) + x_i) * TILEDATA_BSIZE;

    // write up to the end of the current column (at most) initially
    towrite = unsigned_min(TILELAYER_HEIGHT - y_i, count);
    written = 0;                      // Keep track of how many tiles we've written so far
    while (written < count) // This loop should run twice at most
    {
        while(towrite != 0 && written < count)
        {
            // These column writes cause this function to be very inefficient.
            // No real way around these single-tile writes, unfortunately.
            if (pwrite(ppu_fd, &write_tiles[written], TILEDATA_BSIZE, start_addr) != TILEDATA_BSIZE)
            {
                assert(errno == EBUSY);

                return -1; // In this case, PPU is busy (errno == EBUSY)
            }
            written++;
            towrite--;
            // Increment start address by an entire row
            start_addr += TILELAYER_WIDTH * TILEDATA_BSIZE;
        }
        towrite = count - written; // Write the leftover tiles next (if any)
        // Wrap around to 0th row, starting at the fixed column
        start_addr = tile_layer_offset + x_i * TILEDATA_BSIZE; 
    }

    free(write_tiles);

    return 0;
}

int ppu_write_pattern(pattern_t *pattern, unsigned width, unsigned height,
                      pattern_addr_t pattern_addr)
{
    // Check for invalid inputs and notify user of errors
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");
    nowaymsg(pattern == NULL, "Pattern array is NULL!");
    nowaymsg(pattern_addr > PATTERN_MAXADDR, "Pattern address malformed!");

    unsigned x_i = pattern_addr & 0x1F;        // Starting tile x coord. 1st 5 bits of pattern_addr
    unsigned y_i = (pattern_addr >> 5) & 0x1F; // Starting tile y coord. 2nd 5 bits of pattern_addr
    for (unsigned row = 0; row < height; row++) // Write rows of tile-patterns
    {
        unsigned y_f = (y_i + row) & 0x1F; // This performs mod 32 to create wrap-around
        for (unsigned col = 0; col < width; col++) // For each tile-pattern in the current row
        {
            unsigned x_f = (x_i + col) & 0x1F; // This performs mod 32 to create wrap-around
            unsigned addr = ppu_pattern_addr(x_f, y_f); // Tile address
            unsigned wr_addr = VRAM_PATTERNOFFSET + TILEPATTERN_BSIZE * addr; // Byte address
            unsigned srcaddr = col + width * row; // Address into pattern array

            // write a full 8x8 tile's worth of pattern data:
            if (pwrite(ppu_fd, &(pattern[srcaddr].pxrow), TILEPATTERN_BSIZE, wr_addr) != TILEPATTERN_BSIZE)
            {
                assert(errno == EBUSY);

                return -1; // In this case, PPU is busy (errno == EBUSY)
            }
        }
    }

    return 0;
}

int ppu_write_palette(palette_t *palette, layer_e layer_id, unsigned palette_id)
{
    unsigned wr_addr;
    unsigned layer_offset;
    
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");
    nowaymsg(palette == NULL, "Palette is NULL!");

    if (layer_id == LAYER_SPR)
    {
        nowaymsg(palette_id >= PALETTERAM_SPRITEMAX, "Attempting to access palette out of bounds!");
        layer_offset = PALETTERAM_SPROFFSET;
    }
    else
    {
        nowaymsg(palette_id >= PALETTERAM_TILEMAX, "Attempting to access palette out of bounds!");
        layer_offset = (layer_id == LAYER_FG) ? PALETTERAM_FGOFFSET : PALETTERAM_BGOFFSET;
    }

    // Offset by one color (4B) (to ignore the transparent one)
    wr_addr = VRAM_PALETTEOFFSET + layer_offset + palette_id * PALETTE16_BSIZE + 4;

    // Only write the opaque 15 colors
    if (pwrite(ppu_fd, &(palette->color), PALETTE15_BSIZE, wr_addr) != PALETTE15_BSIZE)
    {
        assert(errno == EBUSY);

        return -1; // In this case, PPU is busy (errno == EBUSY)
    }

    return 0;
}

int ppu_write_sprites(sprite_t *sprites, unsigned len, unsigned sprite_id_i)
{
    unsigned i;
    uint32_t *sprite_buf;
    uint32_t *sprite_extra_buf;
    uint32_t wraddr;
    uint32_t wraddr_extra;
    uint32_t sprite;
    uint8_t extra;

    nowaymsg(sprites == NULL, "Sprite Array is NULL!");
    nowaymsg(sprite_id_i + len > SPRITE_MAXCOUNT, "Sprite write would exceed Sprite RAM bounds!");

    nowaymsg((sprite_buf = malloc(len * SPRITE_BSIZE)) == NULL, "Sprite data malloc failed!");
    nowaymsg((sprite_extra_buf = malloc(len)) == NULL, "Sprite extra data malloc failed!");

    wraddr = VRAM_SPRITESOFFSET + sprite_id_i * SPRITE_BSIZE;
    wraddr_extra = VRAM_SPRITESOFFSET + SPRRAM_EXTRAOFFSET + sprite_id_i; // Size is 1B for extra

    for (i=0; i < len; i++)
    {
        // TODO: Check for malformed inputs for this sprite
        nowaymsg(sprites[i].pattern_addr > PATTERN_MAXADDR, "Pattern address malformed!");
        nowaymsg(sprites[i].palette_id >= SPRLAYER_MAX_PALETTES, "Palette ID out of range!");
        nowaymsg(sprites[i].y >= 240, "Sprite y coord. out of range!");
        nowaymsg(sprites[i].x >= 320, "Sprite x coord. out of range!");
        nowaymsg(sprites[i].mirror > MIRROR_MAXVAL, "Mirror argument malformed!");
        // ...

        sprite = (sprites[i].pattern_addr << 22) | (sprites[i].palette_id << 17) | (sprites[i].y << 9) | sprites[i].x;
        extra = (sprites[i].mirror << 6) | ((sprites[i].height - 1) << 4) | ((sprites[i].width - 1) << 2) | sprites[i].prio;

        printf("Sprite: %X\n", sprite);
        printf("extra: %X\n", extra);

        sprite_buf[i] = sprite;
        sprite_extra_buf[i] = extra;
    }

    if (pwrite(ppu_fd, sprite_buf, len * SPRITE_BSIZE, wraddr) != (ssize_t)len * SPRITE_BSIZE)
    {
        assert(errno == EBUSY);

        return -1; // In this case, PPU is busy (errno == EBUSY)
    }
    
    if (pwrite(ppu_fd, sprite_extra_buf, len, wraddr_extra) != (ssize_t)len)
    {
        assert(errno == EBUSY);

        return -1; // In this case, PPU is busy (errno == EBUSY)
    }

    free(sprite_buf);
    free(sprite_extra_buf);

    return 0;
}

int ppu_set_bgcolor(unsigned color)
{
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");

    if (ioctl(ppu_fd, IOCTL_PPU_SET_BGCOLOR, color & COLOR_24MASK) < 0)
    {
        assert(errno == EBUSY); // Otherwise, it is an EINVAL, which is OUR fault.

        return -1;
    }

    return 0;
}

int ppu_set_scroll(layer_e tile_layer, unsigned scroll_x, unsigned scroll_y)
{
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");
    nowaymsg(tile_layer == LAYER_SPR, "FP-GAme PPU does not support Sprite Layer scrolling!");

    uint32_t scroll = (scroll_y << 16) | scroll_x;
    unsigned long ioctl_num = (tile_layer == LAYER_FG) ? IOCTL_PPU_SET_FGSCROLL : IOCTL_PPU_SET_BGSCROLL;

    if (ioctl(ppu_fd, ioctl_num, scroll) < 0)
    {
        assert(errno == EBUSY); // Otherwise, it is an EINVAL, which is OUR fault.

        return -1;
    }
    return 0;
}

int ppu_set_layer_enable(unsigned enable_mask)
{
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");

    if (ioctl(ppu_fd, IOCTL_PPU_SET_ENABLE, enable_mask & LAYER_ENMASK) < 0)
    {
        assert(errno == EBUSY); // Otherwise, it is an EINVAL, which is OUR fault.

        return -1;
    }

    return 0;
}


/* ======================== */
/* === Helper Functions === */
/* ======================== */
unsigned unsigned_min(unsigned a, unsigned b)
{
    return (a < b) ? a : b;
}