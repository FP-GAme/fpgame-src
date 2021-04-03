/*
 * File: i2s_out.sv
 * Author: Andrew Spaulding
 *
 * This file contains a module which takes in parallel input
 * and converts it into i2s output. It is used to simplify the interface
 * to the APU and make the APU independent of the sampling rate of i2s.
 */

`define SAMPLE_MSB 4'd15

module i2s_comm
(
	input  logic clock, reset_l, /* Expects 1.024MHz clock. */
	input  logic [15:0] sample,  /* Sent out in mono. */

	output logic i2s_out,
	output logic i2s_ws
);

/*** Wires ***/

/*
 * We hold the active sample, so the sender need only hold for one
 * clock cycle (from our perspective).
 */
logic [15:0] active_sample, next_active_sample;

/*
 * Holds the index of the current bit being sent.
 * Note that bits are sent msb first.
 */
logic [3:0] bit_idx, next_bit_idx;

/*
 * We use these states to ensure a smooth transition into the correct value
 * for the word select line at the correct time.
 */
enum { INIT, RUNNING } state, next_state;
logic next_i2s_ws;

logic switch_sample;

/*** Combonational Logic ***/

assign switch_sample = (bit_idx == 'b0);

always_comb begin
	next_state = RUNNING;

	unique case (state)
	INIT: begin
		next_active_sample = active_sample;
		next_bit_idx = bit_idx;
		next_i2s_ws = i2s_ws;
		i2s_out = active_sample[bit_idx];
	end
	RUNNING: begin
		next_active_sample = (switch_sample & i2s_ws) ? sample : active_sample;
		next_bit_idx = (switch_sample) ? `SAMPLE_MSB : bit_idx - 4'd1;
		next_i2s_ws = (next_bit_idx == 'b0) ? ~i2s_ws : i2s_ws;
		i2s_out = active_sample[bit_idx];
	end
	endcase
end

/*** Sequential Logic ***/

always_ff @(negedge clock, negedge reset_l) begin
	if (~reset_l) begin
		bit_idx <= `SAMPLE_MSB;
		active_sample <= 'd0;
		state <= INIT;
		i2s_ws <= 1'b1;
	end else begin
		state <= next_state;
		bit_idx <= next_bit_idx;
		active_sample <= next_active_sample;
	end
end

endmodule : i2s_comm
