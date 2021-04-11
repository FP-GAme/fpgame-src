// Avalon_Master.v

// This file was auto-generated as a prototype implementation of a module
// created in component editor.  It ties off all outputs to ground and
// ignores all inputs.  It needs to be edited to make it do something
// useful.
//
// This file will not be automatically regenerated.  You should check it in
// to your version control system if you want to keep it.

`timescale 1 ps / 1 ps
module Avalon_Master (
		output wire [31:0] avm_m0_address,       //      avm_m0.address
		output wire        avm_m0_read,          //            .read
		input  wire        avm_m0_waitrequest,   //            .waitrequest
		input  wire [63:0] avm_m0_readdata,      //            .readdata
		input  wire        avm_m0_readdatavalid, //            .readdatavalid
		input  wire        clock_clk,            //       clock.clk
		input  wire        reset_reset,          //       reset.reset
		input  wire [31:0] addr,                 // conduit_end.avm_addr
		input  wire        read,                 //            .avm_read
		output wire [63:0] readdata,             //            .avm_readdata
		output wire        readdatavalid,        //            .avm_readdatavalid
		output wire        waitrequest           //            .avm_waitrequest
	);

	assign avm_m0_address = addr;
	assign avm_m0_read = read;
	assign readdata = avm_m0_readdata;
	assign waitrequest = avm_m0_waitrequest;
	assign readdatavalid = avm_m0_readdatavalid;

endmodule
