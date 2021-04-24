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
	input  sprite_conf_t conf,
	input  logic [1:0] index,

	input  logic [7:0] row,

	output logic [12:0] addr
);

/*** Wires ***/

logic [4:0] tile_x, tile_y, row_offset, row_index;
logic [2:0] tile_row;

/*** Combonational Logic ***/

assign row_offset = row - conf.y;
assign row_index = (conf.y_mirror) ? (({ conf.h, 3'd0 } - 5'd1) - row_offset)
                                   : row_offset;

assign tile_x = conf.tile[4:0] + { 3'd0, index };
assign tile_y = conf.tile[9:5] + { 3'd0, row_index[4:3] };
assign tile_row = row_index[2:0];

assign addr = { tile_y, tile_x, tile_row };

endmodule : sprite_addr_gen
