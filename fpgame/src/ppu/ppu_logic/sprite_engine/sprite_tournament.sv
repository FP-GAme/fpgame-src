/*
 * File: sprite_tournament.sv
 * Author: Andrew Spaulding
 *
 * Certainly, they existed...
 * Those blinded by ambition.
 * Those consumed with vengeance.
 * But here they do not exist.
 * Only winners and losers here.
 * For here, THE MIGHTY RULE!
 *
 * Takes in a variable number of sprite units, and determines which unit
 * should output its pixel based on the units fg/bg priority, transparency,
 * and order in OAM.
 */

`include "sprite_defines.vh"

module sprite_tournament
#(parameter SPRITES=`MAX_SPRITES_PER_LINE)
(
	input  sprite_pixel_t [SPRITES - 1:0] in;
	input  logic [8:0] col;
	output logic [8:0] pixel_addr;
);

/*** Wires ***/

logic [SPRITES - 1:0] fg, bg, visible, sel_mask;
logic [$clog2(SPRITES):0] select;
logic exists;

/*** Combonational Logic ***/

genvar i;
generate
	for (i = 0; i < SPRITES; i = i + 1) begin : tournament_gen
		 assign fg[i] = in[i].fg_prio;
		 assign bg[i] = in[i].bg_prio;
		 assign visible[i] = ~in[i].transparent;
	end
endgenerate

always_comb begin
	if ((fg & visible) != 'd0) begin
		sel_mask = fg & visible;
	end else if ((bg & visible) != 'd0) begin
		sel_mask = bg & visible;
	end else begin
		sel_mask = visible;
	end

	/* Gets the index of the LSB */
	select = $right(sel_mask)
end

assign exists = (visible != 'd0);
assign pixel_addr = (exists) ? { in[select].palette, in[select].pixel } : 'd0;

endmodule : sprite_tournament
