// new_component.v

// This file was auto-generated as a prototype implementation of a module
// created in component editor.  It ties off all outputs to ground and
// ignores all inputs.  It needs to be edited to make it do something
// useful.
//
// This file will not be automatically regenerated.  You should check it in
// to your version control system if you want to keep it.

`timescale 1 ps / 1 ps
module pio_async_write (
		input  wire [1:0]  avs_s0_address,   //      avs_s0.address
		input  wire        avs_s0_write,     //            .write
		input  wire [31:0] avs_s0_writedata, //            .writedata
		input  wire        clock_clk,        //       clock.clk
		input  wire        reset_reset,      //       reset.reset
		output wire        write_valid,      // conduit_end.new_signal
		output wire [31:0] write_data
	);

	assign write_data = avs_s0_writedata;
	assign write_valid = avs_s0_write;

endmodule
