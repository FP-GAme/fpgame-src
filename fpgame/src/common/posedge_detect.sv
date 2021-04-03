/*
 * File: posedge_detect.sv
 * Author: Andrew Spaulding
 *
 * Detects a positive edge, between two clock cycles, on the given input
 * signal.
 */

module posedge_detect
(
	input  logic clock, reset_l,
	input  logic in,
	output logic out
);

/*** Wires ***/

logic last_in, next_last_in, next_out;

/*** Combonational Logic ***/

assign next_last_in = in;
assign next_out = ~last_in & in;

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		out <= 1'b0;
		last_in <= 1'b0;
	end else begin
		last_in <= next_last_in;
		out <= next_out;
	end
end

endmodule : posedge_detect
