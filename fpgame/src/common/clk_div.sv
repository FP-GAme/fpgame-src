/*
 * Uses a counter to divide the given clock.
 *
 * Can be used internally as a regular counter, but should not be used
 * as an actual clock internally.
 */
module clock_div
	#(parameter LEVEL_WIDTH=1)
(
	input logic clock,
	input logic reset,
	output logic neg_change,
	output logic pos_change,
	output logic div_clk
);

logic next_level, tick, level;

timer #(LEVEL_WIDTH) t0 (.clock, .reset, .tick);

assign next_level = (tick) ? ~level : level;
assign neg_change = tick & level;
assign pos_change = tick & ~level;

always_ff @(posedge clock, negedge reset) begin
	if (~reset) begin
		level <= 0;
	end else begin
		level <= next_level;
	end
end

assign div_clk = level;

endmodule : clock_div
