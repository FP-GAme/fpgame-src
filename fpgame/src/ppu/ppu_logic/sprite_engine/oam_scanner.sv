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

enum logic [1:0] { INIT, STANDBY, MEM_REQ } state, next_state;

logic [8:0] h_limit;
logic [2:0] h_offset;
logic oam_addr_inc;
logic in_range;
logic more_conf;

/*** Modules ***/

counter #($clog2(`MAX_SPRITES) + 1) oam_addr_cnt(
          .clock, .reset_l, .clear, .inc(oam_addr_inc), .out(oam_addr));

/*** Combonational Logic ***/

assign more_conf = (oam_addr < `MAX_SPRITES);
assign h_offset = oam_data.h + 3'd1;
assign h_limit = oam_data.y + { h_offset, 3'd0 };
assign in_range = (oam_data.y <= row) && (row < h_limit);

always_comb begin
	oam_read = 1'b0;
	oam_addr_inc = 1'b0;
	conf_ack = 1'b0;
  conf_exists = more_conf;

	unique case (state)
	INIT: begin
		// FIXME: Why is this state even here?
		next_state = (clear) ? STANDBY : INIT;
	end
	STANDBY: begin
		oam_read = (conf_req && conf_exists);
		oam_addr_inc = oam_read;
		next_state = (oam_read & ~clear) ? MEM_REQ : STANDBY;
	end
	MEM_REQ: begin
	  conf_exists = 1'b1;
		next_state = (oam_avail | clear)
		           ? ((more_conf) ? STANDBY : INIT)
			   : MEM_REQ;
		conf_ack = in_range & oam_avail;
	end
	endcase
end

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		state <= INIT;
	end else begin
		state <= next_state;
	end
end

endmodule : oam_scanner
