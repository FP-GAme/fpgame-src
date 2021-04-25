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
#define PATTERN_MAXADDR 1023      ///< Maximum pattern_addr_t value
#define MIRROR_MAXVAL 3           ///< Maximum allowable value for mirror_e
#define SPRITE_MAXWIDTH 4         ///< Maximum allowable sprite width
#define SPRITE_MAXHEIGHT 4        ///< Maximum allowable sprite height
#define SPRITE_MAXCOUNT 64        ///< Maximum supported sprites
#define PRIO_MAX_VALUE 2          ///< Maximum allowable value for render_prio_e
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
#define TILECHUNK_WIDTH 4         ///< Width of a single tile-chunk (group of 4x4 tile-patterns)
#define TILECHUNK_HEIGHT 4        ///< Height of a single tile-chunk (group of 4x4 tile-patterns)
#define TILEDATA_BSIZE 2          ///< Size of tile data in bytes
#define PALETTE_BSIZE 60          ///< Size of 15 colors (a single palette)
#define SPRITE_BSIZE 4            ///< Size of sprite data in bytes


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
pattern_addr_t ppu_pattern_addr (unsigned pattern_id, unsigned x, unsigned y)
{
    nowaymsg(pattern_id > 63, "Argument out of range!");
    nowaymsg(x > 3, "Argument out of range!");
    nowaymsg(y > 3, "Argument out of range!");

    return (pattern_id << 4) | (y << 2) | x;
}

tile_t ppu_make_tile(pattern_addr_t pattern_addr, unsigned palette_id, mirror_e mirror)
{
    nowaymsg(pattern_addr > PATTERN_MAXADDR, "Pattern address malformed!");
    nowaymsg(palette_id > TILELAYER_MAX_PALETTES, "Palette ID out of range!");
    nowaymsg(mirror > MIRROR_MAXVAL, "Mirror argument malformed!");

    return (pattern_addr << 6) | (palette_id << 2) | mirror;
}

void ppu_make_sprite(sprite_t *sprite, pattern_addr_t pattern_addr, unsigned width, unsigned height,
                     unsigned palette_id, render_prio_e prio, mirror_e mirror)
{
    nowaymsg(sprite == NULL, "Sprite points to NULL!");
    nowaymsg(pattern_addr > PATTERN_MAXADDR, "Pattern address malformed!");
    nowaymsg(width > SPRITE_MAXWIDTH, "Sprites widths larger than 4 tiles are not supported!");
    nowaymsg(height > SPRITE_MAXHEIGHT, "Sprite heights larger than 4 tiles are not supported!");
    nowaymsg(palette_id > TILELAYER_MAX_PALETTES, "Palette ID out of range!");
    nowaymsg(prio > PRIO_MAX_VALUE, "Priority argument malformed!");
    nowaymsg(mirror > MIRROR_MAXVAL, "Mirror argument malformed!");

    sprite->pattern_addr = pattern_addr;
    sprite->palette_id = palette_id;
    sprite->mirror = mirror;
    sprite->prio = prio;
    sprite->x = 0;
    sprite->y = 0;
    sprite->height = height;
    sprite->width = width;
}

void ppu_load_tilemap(tile_t *tilemap, unsigned len, char *file)
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

void ppu_load_pattern(pattern_t *pattern, char *file)
{
    FILE *fp;
    int result;
    uint32_t row_pattern;
    unsigned count;       // Pattern rows written so far

    nowaymsg(pattern == NULL, "Tile array is NULL!");

    fp = fopen(file, "r");
    nowaymsg(fp == NULL, strerror(errno));

    count = 0;
    do {
        // Reads the format (XXX,X,X) into (patter_addr, palette_id, mirror)
        result = fscanf(fp, "%8X\n", &row_pattern);

        // Source txt files have reversed nibble ordering (for ease of use).
        // We need to reverse them back:
        row_pattern = ((row_pattern & 0x0F0F0F0F) << 4) | ((row_pattern & 0xF0F0F0F0) >> 4);
        row_pattern = ((row_pattern & 0x00FF00FF) << 8) | ((row_pattern & 0xFF00FF00) >> 8);
        row_pattern = ((row_pattern & 0x0000FFFF) << 16) | ((row_pattern & 0xFFFF0000) >> 16);
        // Credit to https://stackoverflow.com/questions/58716959/reversing-the-nibbles

        pattern->pxrow[count] = row_pattern;
        count++;
    } while(result != EOF && count < 8);

    result = fclose(fp);
    nowaymsg(result == EOF, strerror(errno));
}

void ppu_load_palette(palette_t *palette, char *file)
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
int ppu_write_tiles_horizontal(tile_t *tiles, unsigned len, unsigned x_i, unsigned y_i,
                               unsigned count)
{
    unsigned i;            // Generic reusable loop iterator
    unsigned start_addr;   // Actual Byte-address in VRAM to write to.
    unsigned towrite;      // How many tiles to write for this writing iteration.
    unsigned written;      // Keep track of how many tiles we have written so far.
    tile_t *write_tiles;   // Buffer of tiles to write, taking into account tile repeat/loop.

    // Catch input errors and tell the user
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");
    nowaymsg(x_i >= TILELAYER_WIDTH, "Initial write position out of bounds!");
    nowaymsg(y_i >= TILELAYER_HEIGHT, "Initial write position out of bounds!");
    nowaymsg(tiles == NULL, "Tile array is NULL!");

    // Catch case where nothing should occur
    if (count == 0 || len == 0) return 0;

    // Clamp len and count to the width of the tile layer. It makes no sense to overwrite more than
    //   a full layer at once.
    count = (count > TILELAYER_WIDTH) ? TILELAYER_WIDTH : count;
    len = (len > TILELAYER_WIDTH) ? TILELAYER_WIDTH : len;

    // We split the tile writing operation into two writes:
    //   1. Write from x_i until either the end of the row, or until we've written count tiles.
    //   2. If we have reached the end of the row, but haven't written count tiles in total, we must
    //      continue writing tiles by wrapping around to the start of the current row.

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

    // (64 tiles/row * y_i rows + x_i tiles) * 2B per tile. Note: No offset from VRAM start
    start_addr = ((y_i << 6) + x_i) * TILEDATA_BSIZE;

    towrite = TILELAYER_WIDTH - x_i; // write up to the end of the current row initially
    written = 0;                     // Keep track of how many tiles we've written so far
    while (written < count)
    {
        if (pwrite(ppu_fd, &write_tiles[written], towrite * TILEDATA_BSIZE, start_addr) != (ssize_t)towrite * TILEDATA_BSIZE)
        {
            assert(errno == EBUSY);

            return -1; // In this case, PPU is busy (errno == EBUSY)
        }
        written += towrite;
        towrite = count - written; // Prepare to write the leftover tiles next (if any)
        // Wrap around to the start of the current row
        start_addr = (y_i * TILELAYER_HEIGHT) * TILEDATA_BSIZE;
    }

    free(write_tiles);

    return 0;
}

int ppu_write_tiles_vertical(tile_t *tiles, unsigned len, unsigned x_i, unsigned y_i,
                             unsigned count)
{
    unsigned i;            // Generic reusable loop iterator
    unsigned start_addr;   // Actual Byte-address in VRAM to write to.
    unsigned towrite;      // How many tiles to write for this writing iteration.
    unsigned written;      // Keep track of how many tiles we have written so far.
    tile_t *write_tiles;   // Buffer of tiles to write, taking into account tile repeat/loop.

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

    // (64 tiles/row * y_i rows + x_i tiles) * 2B per tile. Note: No offset from VRAM start.
    start_addr = ((y_i << 6) + x_i) * TILEDATA_BSIZE;

    towrite = TILELAYER_HEIGHT - y_i; // write up to the end of the current column initially
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
        towrite = count - written;         // Write the leftover tiles next (if any)
        start_addr = x_i * TILEDATA_BSIZE; // Wrap around to 0th row, starting at the fixed column
    }

    free(write_tiles);

    return 0;
}

int ppu_write_pattern(pattern_t *pattern, unsigned width, unsigned height,
                      pattern_addr_t pattern_addr)
{
    unsigned row;
    unsigned col;
    unsigned addr;    // Write address in terms of pattern_t
    unsigned wr_addr; // Final byte-address for write
    unsigned srcaddr; // Address into patterns array
    unsigned x_i;
    unsigned y_i;

    // Check for invalid inputs and notify user of errors
    nowaymsg(ppu_fd == -1, "PPU not enabled or owned by this process!");
    nowaymsg(pattern == NULL, "Pattern array is NULL!");

    // pattern_addr's x_i, y_i as well as the specified width and height must not cause out-of-
    //   -bounds access, or extend beyond the given tile chunk.
    x_i = pattern_addr & 0x3;
    y_i = (pattern_addr >> 2) & 0x3;
    nowaymsg(x_i > TILECHUNK_WIDTH - width, "Pattern extends out of tile-chunk bounds!");
    nowaymsg(y_i > TILECHUNK_HEIGHT - height, "Pattern extends out of tile-chunk bounds!");
    nowaymsg(pattern_addr + width * height > PATTERN_MAXADDR, "Pattern extends out of Pattern RAM!");

    for (row = 0; row < height; row++) // Write rows of tile-patterns
    {
        for (col = 0; col < width; col++) // For each tile-pattern in the current row
        {
            addr = pattern_addr + row * 4 + col;
            wr_addr = VRAM_PATTERNOFFSET + TILEPATTERN_BSIZE * addr;
            srcaddr = col + width * row;

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

    wr_addr = VRAM_PALETTEOFFSET + layer_offset + palette_id * PALETTE_BSIZE + 4; // Offset by one color

    if (pwrite(ppu_fd, &(palette->color), PALETTE_BSIZE, wr_addr) != PALETTE_BSIZE)
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
        sprite = (sprites[i].pattern_addr << 22) | (sprites[i].palette_id << 17) | (sprites[i].y << 9) | sprites[i].x;
        extra = (sprites[i].mirror << 6) | (sprites[i].width << 4) | (sprites[i].height << 2) | sprites[i].prio;

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