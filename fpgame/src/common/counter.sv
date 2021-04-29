/*
 * File: counter.sv
 * Author: Andrew Spaulding
 *
 * Bro, it's a counter. What do you want from me?
 */

module counter
#(parameter WIDTH = 8)
(
	input  logic clock, reset_l,
	input  logic inc, clear,
	output logic [WIDTH - 1:0] out
);

logic [WIDTH - 1:0] next_count;

always_comb begin
	next_count = out;

	if (clear) begin
		next_count = 'd0;
	end else if (inc) begin
		next_count = out + 'd1;
	end
end

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		out <= 'd0;
	end else begin
		out <= next_count;
	end
end

endmodule : counter
