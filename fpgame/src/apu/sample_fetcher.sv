/*
 * File: sample_fetcher.sv
 * Author: Andrew Spaulding
 *
 * Fetches sample chunks from DDR3 as they are requested. Once 512 bytes have
 * been read from a given base address, no new samples will be fetched until a
 * new base address has been provided and base_valid has been asserted.
 */

module sample_fetcher
(
	input  logic        clock, reset_l,

	input  logic [63:0] mem_data,
	input  logic        mem_ack,
	input  logic        mem_wait,
	output logic [28:0] mem_addr,
	output logic        mem_read_en,

	output logic [63:0] chunk,
	output logic        chunk_valid,
	input  logic        chunk_ack,

	input  logic [28:0] base,
	input  logic        base_valid,
	output logic        base_ack
);

/*** Wires ***/

/* Stored base address for fetching samples */
logic [28:0] addr, next_addr;
logic addr_valid, next_addr_valid;

/* The address of the next chunk to fetch. */
logic [5:0] chunk_addr, next_chunk_addr;
logic chunk_reset;

/* Samples which have been read from RAM and are pending being sent to I2S */
logic [63:0] next_chunk;
logic next_chunk_valid;

/* Tracks the read state for DDR3. */
enum { IDLE, READ_WAIT } ram_state, next_ram_state;

/*** Combonational Logic ***/

always_comb begin
	chunk_reset = (chunk_addr == 6'h3f);

	base_ack = ~addr_valid & base_valid;
	next_addr = (base_ack) ? base : addr;
	next_addr_valid = (base_ack)
	                ? 1'b1
			: ((mem_ack & chunk_reset) ? 1'b0 : addr_valid);

	mem_addr = addr + { 23'd0, chunk_addr };
	unique case (ram_state)
	IDLE: begin
		mem_read_en = (~chunk_valid & addr_valid);
		next_ram_state = (mem_read_en & ~mem_wait) ? READ_WAIT : IDLE;

		next_chunk = chunk;
		next_chunk_valid = ~chunk_ack & chunk_valid;
		next_chunk_addr = chunk_addr;
	end
	READ_WAIT: begin
		mem_read_en = 'b0;
		next_ram_state = (mem_ack) ? IDLE : READ_WAIT;

		next_chunk = mem_data;
		next_chunk_valid = mem_ack;
		next_chunk_addr = (mem_ack) ? chunk_addr + 'd1 : chunk_addr;
	end
	endcase
end

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		addr <= 'd0;
		addr_valid <= 'd0;
		chunk <= 'd0;
		chunk_addr <= 'd0;
		chunk_valid <= 'd0;
		ram_state <= IDLE;
	end else begin
		addr <= next_addr;
		addr_valid <= next_addr_valid;
		chunk <= next_chunk;
		chunk_addr <= next_chunk_addr;
		chunk_valid <= next_chunk_valid;
		ram_state <= next_ram_state;
	end
end

endmodule : sample_fetcher
