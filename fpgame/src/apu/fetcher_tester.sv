module fetcher_tester();
	// Basic dut connections.
	logic clock, reset_l;

	logic [63:0] mem_data;
	logic [28:0] mem_addr;
	logic mem_ack, mem_wait, mem_read_en;

	logic [63:0] chunk;
	logic chunk_valid, chunk_ack;

	logic [28:0] base;
	logic base_valid, base_ack;

	sample_fetcher nwa(.clock, .reset_l, .mem_data, .mem_addr, .mem_ack,
	                   .mem_wait, .mem_read_en, .chunk, .chunk_valid,
			   .chunk_ack, .base, .base_valid, .base_ack);

	// Setup clock and reset the DUT.
	initial begin
		clock = 0;
		repeat (2000) #5 clock = ~clock;
	end

	// Cycle chunk ack every four cycles.
	initial begin
		chunk_ack <= 0;
		repeat (1000) begin
			@(posedge clock);
			@(posedge clock);
			@(posedge clock);
			@(posedge clock);
			chunk_ack <= ~chunk_ack;
		end
	end

	// Cycle mem_wait every 3 cycles.
	initial begin
		mem_wait <= 0;
		repeat (1000) begin
			@(posedge clock);
			@(posedge clock);
			@(posedge clock);
			mem_wait <= ~mem_wait;
		end
	end

	// Cycle mem_ack every five cycles.
	initial begin
		mem_ack <= 0;
		repeat (1000) begin
			@(posedge clock);
			@(posedge clock);
			@(posedge clock);
			@(posedge clock);
			@(posedge clock);
			mem_ack <= ~mem_ack;
		end
	end

	initial begin
		base <= 'd0;
		base_valid <= 'd0;
		mem_data <= 64'h8877665544332211;
		reset_l <= 0;
		@(posedge clock);
		reset_l <= 1;
		repeat (500) @(posedge clock);
		$finish;
	end
endmodule : fetcher_tester
