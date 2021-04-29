/*
 * File: pattern_wrapper.sv
 * Author: Andrew Spaulding
 *
 * Provides a standard interface for accessing pattern data.
 */

`include "sprite_defines.vh"

module pattern_wrapper
(
	input logic clock, reset_l,

	output logic [11:0] patram_addr,
	input  logic [63:0] patram_rddata,

	input  logic [12:0]  pattern_addr,
	input  logic pattern_read,
	output logic pattern_avail,
	output pixel_t [7:0] pattern_data
);

logic pat_addr, pat_sel;
logic [1:0][31:0] pat_data;

/* Warning: This is an abuse of the debounce module, and a secret contract */
debounce ack_pipe(.clock, .reset_l, .in(pattern_read), .out(pattern_avail));
debounce sel_pipe(.clock, .reset_l, .in(pat_addr), .out(pat_sel));

assign { patram_addr, pat_addr } = pattern_addr;

assign pat_data = patram_rddata;

assign pattern_data = pat_data[pat_sel];

endmodule : pattern_wrapper
