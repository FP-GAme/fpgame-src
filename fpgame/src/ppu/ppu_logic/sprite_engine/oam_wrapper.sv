/*
 * File: oam_wrapper.sv
 * Author: Andrew Spaulding
 *
 * Provides a simple way to both pieces of data from oam at the same time.
 */

`include "sprite_defines.vh"

module oam_wrapper
(
	input logic clock, reset_l,

	output logic [5:0]  sprram_addr_a,
	input  logic [63:0] sprram_rddata_a,
	output logic [5:0]  sprram_addr_b,
	input  logic [63:0] sprram_rddata_b,

	input  logic [6:0]  oam_addr,
	input  logic oam_read,
	output logic oam_avail,
	output sprite_conf_t oam_data
);

logic [2:0] oam_ext_addr, oam_ext_sel;
logic oam_main_addr, oam_main_sel;
logic [1:0][31:0] oam_main_data;
logic [7:0][7:0] oam_ext_data;

/* Warning: This is an abuse of the debounce module, and a secret contract */
debounce ack_pipe(.clock, .reset_l, .in(oam_read), .out(oam_avail));
debounce main_sel(.clock, .reset_l, .in(oam_main_addr), .out(oam_main_sel));
debounce #(3) ext_sel(.clock, .reset_l, .in(oam_ext_addr), .out(oam_ext_sel));

assign { sprram_addr_a, oam_main_addr } = oam_addr;
assign { sprram_addr_b, oam_ext_addr } = `OAM_EXT_OFFSET + oam_addr;

assign oam_main_data = sprram_rddata_a;
assign oam_ext_data = sprram_rddata_b;

assign oam_data = { oam_main_data[oam_main_sel], oam_ext_data[oam_ext_sel] };

endmodule : oam_wrapper
