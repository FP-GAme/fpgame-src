module debounce
	#(parameter WIDTH=1)
(
	input logic clock,
	input logic reset_l,
	input logic [WIDTH-1:0] in,
	output logic [WIDTH-1:0] out
);

logic [WIDTH-1:0] mid;

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		mid <= 'd0;
		out <= 'd0;
	end else begin
		mid <= in;
		out <= mid;
	end
end

endmodule
