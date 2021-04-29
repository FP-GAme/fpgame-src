/*
 * File: oam_scanner.sv
 * Author: Andrew Spaulding
 *
 * Scans OAM for sprites that are visible on the current line, and sends them
 * to the sprite manager.
 */

`include "sprite_defines.vh"

module oam_scanner
(
	input  logic clock, reset_l, clear,

	input  logic [7:0] row,

	input  logic conf_req,
	output logic conf_ack,
	output logic conf_exists,

	output logic [6:0]  oam_addr,
	output logic oam_read,
	input  logic oam_avail,
	input  sprite_conf_t oam_data
);

/*** Wires ***/

enum logic { STANDBY, MEM_REQ } state, next_state;

logic oam_addr_inc;
logic in_range;

/*** Modules ***/

counter #(7) oam_addr_cnt(.clock, .reset_l, .clear,
                          .inc(oam_addr_inc), .out(oam_addr));

/*** Combonational Logic ***/

assign conf_exists = (oam_addr < `MAX_SPRITES);
assign in_range = (oam_data.y <= row)
                && ((oam_data.y + { oam_data.h, 3'd0 }) > row);

always_comb begin
	oam_read = 1'b0;
	oam_addr_inc = 1'b0;
	conf_ack = 1'b0;

	unique case (state)
	STANDBY: begin
		oam_read = (conf_req && conf_exists);
		next_state = (oam_read & ~clear) ? MEM_REQ : STANDBY;
		oam_addr_inc = oam_read;
	end
	MEM_REQ: begin
		next_state = (oam_avail | clear) ? STANDBY : MEM_REQ;
		conf_ack = in_range & oam_avail;
	end
	endcase
end

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		state <= STANDBY;
	end else begin
		state <= next_state;
	end
end

endmodule : oam_scanner
