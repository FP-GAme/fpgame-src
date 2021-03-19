/* Serial in, parallel out reg. */
module shift_reg
	#(parameter WIDTH=16)
(
	input logic clock,
	input logic reset,
	input logic in,
	input logic ld_en,
	output logic [WIDTH-1:0] out
);

logic [WIDTH-1:0] next_out;
assign next_out = (ld_en) ? {out[WIDTH-2:0], in} : out;

always_ff @(posedge clock, negedge reset) begin
	if (~reset) begin
		out <= 'd0;
	end else begin
		out <= next_out;
	end
end

endmodule : shift_reg
