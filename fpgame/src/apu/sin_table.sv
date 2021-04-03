/*
 * Pretends to be DDR3, outputting a simple sine wave
 */

module sin_table
(
	input  logic [28:0] mem_addr,
	input  logic        mem_read_en,
	output logic [63:0] mem_data,
	output logic        mem_ack
);

assign mem_ready = 1'b1;

always_comb begin
	unique case (mem_addr[1:0])
	2'b00: mem_data = 64'h7d756a5a47311900;
	2'b01: mem_data = 64'h1931475a6a757d7f;
	2'b10: mem_data = 64'h838b96a6b9cfe700;
	2'b11: mem_data = 64'he7cfb9a6968b8381;
	endcase
end

endmodule : sin_table
