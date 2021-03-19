`default_nettype none

module tile_engine
(
    input logic rst_n,
    input logic clk_50M,

    // Control Register inputs
    input logic [8:0] scroll_x,
    input logic [8:0] scroll_y,

	// Avalon-MM read-only master signals
    output logic avm_m0_read,
    output logic [31:0] avm_m0_address,
    input logic [31:0] avm_m0_readdata,
    input logic avm_m0_waitrequest
);

logic [31:0] read_latency;

endmodule : tile_engine