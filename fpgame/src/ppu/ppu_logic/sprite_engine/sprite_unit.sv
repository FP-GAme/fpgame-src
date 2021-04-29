/*
 * File: sprite_unit.sv
 * Author: Andrew Spaulding
 *
 * The sprite unit is a simple collection of registers which hold the current
 * sprite state. This state includes:
 *	- The pattern of the sprite visible on the current row.
 *	- The width of the sprite
 *	- The sprite's X-position
 *	- The sprite's fg/bg priority
 *	- The palette being used by the sprite.
 *
 * Sprite units are connected in a chain, with the "left" sprite unit stealing
 * the data of the "right" sprite unit whenever the "right" unit has data and
 * the "left" does not. This is done to allow the sprite manager to simply
 * send data to the sprite unit on its "left", meaning less wires are required
 * in the design.
 */

`include "sprite_defines.vh"

module sprite_unit
(
	input logic clock, reset_l, clear,

	input  sprite_reg_t in,
	input  logic in_valid,
	output logic in_ack,

	output sprite_reg_t out,
	output logic out_valid,
	input  logic out_ack,

	input  logic [8:0] col,
	output sprite_pixel_t pixel
);

/*** Wires ***/

sprite_reg_t next_out;
logic next_out_valid;

logic [8:0] width_limit;
logic [4:0] pat_offset, pat_index;

/*** Combonational Logic ***/

always_comb begin
	in_ack = 1'b0;
	next_out = out;
	next_out_valid = out_valid;

	if (clear | (out_ack & out_valid)) begin
		next_out = 'd0;
		next_out_valid = 1'b0;
	end else if (in_valid) begin
		in_ack = 1'b1;
		next_out = in;
		next_out_valid = 1'b1;
	end
end

assign width_limit = out.conf.x + { out.conf.w, 3'd0 };
assign pat_offset = col - out.conf.x;
assign pat_index = (out.conf.x_mirror)
                 ? (({ out.conf.w, 3'd0 } - 5'd1) - pat_offset)
		 : pat_offset;

assign pixel.palette = out.conf.palette;
assign pixel.pixel = out.pat[pat_index];
assign pixel.fg_prio = out.conf.fg_prio;
assign pixel.bg_prio = out.conf.bg_prio;
assign pixel.transparent = (pixel.pixel == 'd0) || (out.conf.x > col)
                         || (col >= width_limit);

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		out <= 'd0;
		out_valid <= 1'b0;
	end else begin
		out <= next_out;
		out_valid <= next_out_valid;
	end
end

endmodule : sprite_unit
