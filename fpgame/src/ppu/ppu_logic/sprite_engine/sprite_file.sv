/*
 * File: sprite_file.sv
 * Author: Andrew Spaulding
 *
 * Holds the sprite units and the sprite tournament logic, creating a kind of
 * register file of sprites.
 */

`include "sprite_defines.vh"

module sprite_file
#(parameter SPRITES = `MAX_SPRITES_PER_LINE)
(
	input  logic clock, reset_l, clear,

	input  sprite_reg_t in,
	input  logic in_valid,
	output logic in_ack,

	input  logic [8:0] col,
	output logic [8:0] pixel_addr
);

/*** Wires ***/

sprite_pixel_t [SPRITES - 1:0] pixel;
sprite_reg_t [SPRITES - 1:0] pipe;
logic [SPRITES - 1:0] valid, ack;

/*** Modules ***/

sprite_unit (.clock, .reset_l, .clear,
             .in(pipe[0]), .in_valid(valid[0]), .in_ack(ack[0]),
             .out_valid(1'b0),
             .col, .pixel(pixel[0]));

genvar i;
generate
	for (i = 1; i < SPRITES; i = i + 1) begin: su_gen
		sprite_unit (.clock, .reset_l, .clear,
		             .in(pipe[i]), .in_valid(valid[i]), .in_ack(ack[i]),
			     .out(pipe[i-1]), .out_valid(valid[i-1]),
			     .out_ack(ack[i-1]),
			     .col, .pixel(pixel[i]));
	end
endgenerate

sprite_tournament(.in(pixel), .col, .pixel_addr);

/*** Combonational Logic ***/

assign pipe[SPRITES - 1] = in;
assign valid[SPRITES - 1] = in_valid;
assign ack[SPRITES - 1] = in_ack;

endmodule : sprite_file
