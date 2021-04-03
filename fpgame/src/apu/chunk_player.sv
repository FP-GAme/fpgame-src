/*
 * File: chunk_player.sv
 * Author: Andrew Spaulding
 *
 * This file provides a module which takes in a chunk of sample and plays
 * the samples one at a time as requested. If the chunk is exausted, and no
 * new chunk is available, then the last sample is played until new data
 * is received.
 */

module chunk_player
(
	input  logic        clock, reset_l,

	input  logic [63:0] chunk,
	input  logic        chunk_valid,
	output logic        chunk_ack,

	input  logic        sample_req,
	output logic [7:0]  sample
);

/*** Wires ***/

logic [7:0][7:0] sample_arr, next_sample_arr;
logic [2:0] sample_idx, next_sample_idx;
logic arr_valid, next_arr_valid;

/*** Combonational Logic ***/

assign chunk_ack = chunk_valid & ~arr_valid;
assign sample = sample_arr[sample_idx];

always_comb begin
	next_sample_idx = sample_idx;
	next_sample_arr = sample_arr;
	next_arr_valid = arr_valid;

	if (chunk_ack) begin
		next_sample_idx = 3'd0;
		next_sample_arr = chunk;
		next_arr_valid = 1'd1;
	end else if ((sample_idx == 'd7) & (sample_req)) begin
		next_arr_valid = 1'd0;
	end else if (sample_req) begin
		next_sample_idx = sample_idx + 3'd1;
	end
end

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		sample_arr <= 'd0;
		sample_idx <= 'd0;
		arr_valid <= 'd0;
	end else begin
		sample_arr <= next_sample_arr;
		sample_idx <= next_sample_idx;
		arr_valid <= next_arr_valid;
	end
end

endmodule : chunk_player
