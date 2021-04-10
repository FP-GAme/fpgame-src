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
	input  logic        clock, reset_l, /* 50KHz clock. */
	input  logic [2:0]  control,
	input  logic        control_valid,  /* Control from MMIO. */
	input  logic [28:0] buf_base,
	input  logic        buf_valid,      /* New buf from MMIO. */
	output logic        buf_irq,

	input  logic [63:0] mem_data,
	input  logic        mem_ack,        /* DDR3 data is valid. */
	input  logic        mem_wait,
	output logic [28:0] mem_addr,
	output logic        mem_read_en,

	input  logic        i2s_clk,
	output logic        i2s_out,
	output logic        i2s_ws
);

/*** Wires ***/

logic apu_en, next_apu_en;
logic enq_base;
logic irq_en, next_irq_en, irq_ack, irq_req, next_buf_irq;

logic [28:0] queued_base, next_queued_base;
logic queued_base_valid, next_queued_base_valid;
logic queued_base_ack;

/* Module interconnect */

logic [16:0] i2s_sample;
logic [7:0] sample;

logic [63:0] chunk;
logic chunk_valid, chunk_ack;

logic debounce_i2s_ws, sample_req;

/*** Modules ***/

sample_fetcher(.clock, .reset_l, .mem_data, .mem_ack, .mem_addr, .mem_read_en,
               .mem_wait, .chunk, .chunk_valid, .chunk_ack, .base(queued_base),
               .base_valid(queued_base_valid), .base_ack(queued_base_ack));

chunk_player(.clock, .reset_l, .chunk, .chunk_valid, .chunk_ack, .sample,
             .sample_req);

posedge_detect(.clock, .reset_l, .in(debounce_i2s_ws), .out(sample_req));

debounce(.clock, .reset_l, .in(i2s_ws), .out(debounce_i2s_ws));

/*
 * Important: It isn't, strictly speaking, safe to connect an output from one
 * clock domain to another without debouncing it. However, we know that the
 * chunk player is running ~50x faster than the i2s communication module and
 * that it won't change the sample late in the i2s clocks cycle. The sample
 * will be available at the third clock cycle from the ws switch, which is
 * more than enough time for the flip-flop to react and avoid going
 * meta-stable.
 *
 * The same cannot be said for the edge detection on i2s_ws itself, which is
 * why it is debounced.
 */
i2s_comm(.clock(i2s_clk), .reset_l, .i2s_out, .i2s_ws,
         .sample(i2s_sample));

/*** Combonational Logic ***/

assign i2s_sample = (apu_en) ? { sample, 8'd0 } : 16'd0;

assign irq_ack = control_valid & control[0];
assign irq_req = control_valid & control[1];
assign next_apu_en = control_valid & control[2];

assign next_irq_en = (irq_ack) ? 1'b0 : ((irq_req) ? 1'b1 : irq_en);
assign next_buf_irq = (irq_ack) ? 1'b0 : (irq_en & ~queued_base_valid);

always_comb begin
	next_queued_base = queued_base;
	next_queued_base_valid = queued_base_valid;

	if (buf_valid) begin
		next_queued_base = buf_base;
		next_queued_base_valid = 1'b1;
	end else if (queued_base_ack) begin
		next_queued_base_valid = 1'b0;
	end
end

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		apu_en <= 1'b0;
		irq_en <= 1'b0;
		buf_irq <= 1'b0;
		queued_base <= 'd0;
		queued_base_valid <= 1'b0;
	end else begin
		apu_en <= next_apu_en;
		irq_en <= next_irq_en;
		buf_irq <= next_buf_irq;
		queued_base <= next_queued_base;
		queued_base_valid <= next_queued_base_valid;
	end
end

endmodule : apu
