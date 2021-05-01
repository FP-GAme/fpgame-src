/*
 * File: sprite_addr_gen.sv
 * Author: Andrew Spaulding
 *
 * Takes in a sprite configuration and pattern offset and combonationally
 * determines what address the next pattern should be fetched from.
 */

`include "sprite_defines.vh"

module sprite_addr_gen
(
	input  sprite_conf_t sprite_conf,
	input  logic [1:0] index,

	input  logic [7:0] row,

	output logic [12:0] addr
);

/*** Wires ***/

logic [5:0] mirror_limit;
logic [4:0] tile_x, tile_y, row_offset, row_index;
logic [2:0] tile_row, h_offset;

/*** Combonational Logic ***/

assign row_offset = row - sprite_conf.y;
assign h_offset = sprite_conf.h + 3'd1;
assign mirror_limit = { h_offset, 3'd0 } - 6'd1;
assign row_index = (sprite_conf.y_mirror) ? (mirror_limit - row_offset)
                                          : row_offset;

assign tile_y = sprite_conf.tile[9:5] + { 3'd0, row_index[4:3] };
assign tile_x = sprite_conf.tile[4:0] + { 3'd0, index };
assign tile_row = row_index[2:0];

assign addr = { tile_y, tile_x, tile_row };

endmodule : sprite_addr_gen
