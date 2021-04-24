/*
 * Oh now you KNOW our project is fancy!
 *
 * File: sprite_defines.vh
 * Author: Andrew Spaulding
 *
 * Defines various communication structures and constants for the sprite engine.
 */

`ifndef FPGAME_SPRITE_DEFINES_VH_
`define FPGAME_SPRITE_DEFINES_VH_

/* The maximum number of sprites that can be displayed on a scanline. */
`define MAX_SPRITES_PER_LINE 'd16

/* The number of sprites which can be specified by OAM. */
`define MAX_SPRITES 'd100

/* Defines the pixel type, used internally by the sprite engine. */
typedef logic [3:0] pixel_t;

/*
 * Defines the configuration vector for a sprite, which is pulled from
 * OAM. This structure is stored in OAM as an array of 32-byte upper
 * sections followed by an array of least-significant bytes.
 *
 * The configuration vector for a sprite specifies the tile, palette,
 * position, mirroring, size, and layering attributes of a sprite.
 */
typedef struct packed {
	logic [9:0] tile;
	logic [4:0] palette;
	logic [7:0] y;
	logic [8:0] x;
	logic y_mirror;
	logic x_mirror;
	logic [1:0] h;
	logic [1:0] w;
	logic fg_prio;
	logic bg_prio;
} sprite_conf_t;

/*
 * Holds a stripped down version of a sprites configuration. Used internally
 * after the pattern has been fetched and many of the original configuration
 * fields are no longer necessary.
 */
typedef struct packed {
	logic [4:0] palette;
	logic [8:0] x;
	logic [1:0] w;
	logic x_mirror;
	logic fg_prio;
	logic bg_prio;
} stripped_sprite_conf_t;

/* Holds the values which will be saved by a sprite unit. */
typedef struct packed {
	pixel_t [31:0] pat; // TODO: Verify this argument.
	stripped_sprite_conf_t conf;
} sprite_reg_t;

/* Holds the values which will be used by the sprite tournament logic. */
typedef struct packed {
	logic [4:0] palette;
	pixel_t pixel;
	logic fg_prio;
	logic bg_prio;
	logic transparent;
} sprite_pixel_t

`endif /* FPGAME_SPRITE_DEFINES_VH_
