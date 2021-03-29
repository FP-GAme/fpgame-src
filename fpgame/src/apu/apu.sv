/*
 * File: apu.sv
 * Author: Andrew Spaulding
 *
 * This file contains the primary apu module.
 *
 * The apu takes in samples from DRAM as needed, and outputs them to the I2S
 * module at 32KHz.
 *
 * If the apu is currently playing samples from a known buffer, and no secondary
 * buffer is known, an interrupt will be sent to the cpu so as to request a new
 * secondary buffer.
 *
 * If the primary buffer empties before a new secondary is received, the last
 * sample is played until more data is received.
 */

module apu
(
	input  logic        clock, reset_l,
	input  logic [22:0] queued_buf_addr,
	input  logic        buf_ready,       /* New buffer received from MMIO */
	input  logic [63:0] mem_data,
	input  logic        mem_ready,       /* DDR3 has placed samples on the line. */
	input  logic        sample_req,      /* I2S wants a new sample. */
	output logic [7:0]  sample_out,
	output logic [28:0] mem_addr,
	output logic        mem_read_en,
	output logic        buf_irq
);

/*** Wires ***/

/* Base addresses for the active and queued buffer. */
logic [22:0] active_buf_base, next_active_buf_base, queued_buf_base,
             next_queued_buf_base;

/* We need to track which buffers are valid to know what to play next. */
logic active_buf_valid, next_active_buf_valid, queued_buf_valid,
      next_queued_buf_valid;

/* The address of the next chunk to fetch. */
logic [5:0] chunk_addr, next_chunk_addr;

/* Samples which have been read from RAM and are pending being sent to I2S */
logic [63:0] active_chunk, next_active_chunk, queued_chunk, next_queued_chunk;

/*** Combonational Logic ***/

assign buf_irq = active_buf_valid & ~queued_buf_valid;

assign mem_addr = { active_buf_base, chunk_addr };

assign next_queued_buf_base = (buf_ready) ? queued_buf_addr : queued_buf_base;

// TODO: The rest lmao.

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		active_buf_base <= 'd0;
		active_buf_valid <= 'd0;
		queued_buf_base <= 'd0;
		queued_buf_valid <= 'd0;
		chunk_addr <= 'd0;
		active_chunk <= 'd0;
		queued_chunk <= 'd0;
	end else begin
		active_buf_base <= next_active_buf_base;
		active_buf_valid <= next_active_buf_valid;
		queued_buf_base <= next_queued_buf_base;
		queued_buf_valid <= next_queued_buf_valid;
		chunk_addr <= next_chunk_addr;
		active_chunk <= next_active_chunk;
		queued_chunk <= next_queued_chunk;
	end
end

endmodule : apu
