/* Outputs a 1 to tick every PERIOD cycles. */
module timer
	#(parameter PERIOD)
(
	input logic clock,
	input logic reset,
	output logic tick
);

logic [$clog2(PERIOD):0] next_counter, counter;

always_comb begin
	if (counter == 0) begin
		tick = 1'b1;
		next_counter = PERIOD - 1;
	end else begin
		tick = 1'b0;
		next_counter = counter - 1;
	end
end

always_ff @(posedge clock, negedge reset) begin
	if (~reset) begin
		counter <= PERIOD;
	end else begin
		counter <= next_counter;
	end
end

endmodule
