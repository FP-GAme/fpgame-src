/* indirect_sync_writer.sv
 * Implements an Indirect Sync Writer (as opposed to the regular Sync Writer Module)
 */
/* Overview
 *
 * The Indirect Sync Writer differs from the Sync Writer Module in that it doesn't linearly copy
 *   data from the source RAM to the target RAM. Instead, it accesses the source RAM by using an
 *   address read from an external buffer, and then copies the source into the target RAM.
 *
 */
/* Note About M10K Read Latency
 * The waveform looks like this:
 * --- clk ---
 * Put read address on line
 * --- clk --- read address latched into M10K
 * --- clk --- Read data latched out by M10K
 * 
 * Notice that the read data is latched out by the M10K, meaning it is registered. That means you
 *   can pipeline it into another RM. We take advantage of this below to perform pipelining:
 *
 *   Send addr_buf address (RD) |
 *         --- clk ---          | 
 *                              | Send addr_buf address + 1 (RD)
 *         --- clk ---          |
 *   Receive indirect address,  | 
 *     send it to SRC ram  (RD) |
 *         --- clk ---          |
 *                              | Receive indirect address + 1
 *                              |   and send it to SRC RAM  (RD)
 *         --- clk ---          |
 *   Receive pattern data,      |            ....
 *     write it to target  (WR) |
 */

module indirect_sync_writer #(
    parameter ABUF_ADDR_WIDTH = 6,  // Size of the address line to the address buffer
    parameter ABUF_NUM_ADDR   = 41, // Number of addresses in the address buffer.
                                    // Should be <= total number of addresses than Min(From, To)
    parameter DATA_WIDTH      = 64, // Data width of both source and target
    parameter SRC_ADDR_WIDTH  = 12, // Address width of source
    parameter TARG_ADDR_WIDTH = 6   // Address width of target. Must >= ABUF_ADDR_WIDTH
) (
    // control signals
    input  logic clk,
    input  logic rst_n,
    input  logic sync,
    output logic done,

    // from (address buffer)
    output logic [ABUF_ADDR_WIDTH-1:0] addr_abuf,
    input  logic [SRC_ADDR_WIDTH-1:0]  rddata_abuf,

    // from (source)
    output logic [SRC_ADDR_WIDTH-1:0]  addr_src,
    output logic                       wren_src,
    input  logic [DATA_WIDTH-1:0]      rddata_src,

    // to (destination)
    output logic [TARG_ADDR_WIDTH-1:0] addr_targ,
    output logic [DATA_WIDTH-1:0]      wrdata_targ,
    output logic                       wren_targ

);

enum { IDLE, SYNC } state, n_state;

localparam [ABUF_ADDR_WIDTH-1:0] one = { {(ABUF_ADDR_WIDTH-1){1'b0}}, 1'b1 };

logic n_wren_targ;
logic n_done;

// Counter which determines the target write address. Flat 4 cycles behind addr_abuf counter
logic wr_delay_counter_en;
logic wr_delay_counter_clr;
logic abuf_counter_en;
logic abuf_counter_clr;

up_counter #( .WIDTH(TARG_ADDR_WIDTH) ) wr_delay_counter (
    .clk,
    .rst_n,
    .clr(wr_delay_counter_clr),
    .en(wr_delay_counter_en),
    .count(addr_targ)
);

up_counter #( .WIDTH(ABUF_ADDR_WIDTH) ) abuf_addr_counter (
    .clk,
    .rst_n,
    .clr(abuf_counter_clr),
    .en(abuf_counter_en),
    .count(addr_abuf)
);

assign wren_src = 1'b0; // Always read from source RAM

// the next address into SRC is the address obtained from reading abuf
assign addr_src    = rddata_abuf;
// the next write data we send to target should be the data we have now from src
assign wrdata_targ = rddata_src;

always_comb begin
    n_state = state;
    n_done = 0;

    // Counter control defaults
    abuf_counter_en = 1'b0;
    abuf_counter_clr = 1'b0;
    wr_delay_counter_en = 1'b0;
    wr_delay_counter_clr = 1'b0;

    // next-state write-enable defaults
    n_wren_targ = 1'b0;

    if (state == IDLE) begin
        // Do nothing, unless sync occurs

        // keep counters cleared
        wr_delay_counter_clr = 1'b1;
        abuf_counter_clr = 1'b1;

        if (sync) begin
            n_state = SYNC;

            // start by reading src 0th address
            abuf_counter_clr = 1'b1;
            wr_delay_counter_clr = 1'b1;

            // prepare to write to target
            n_wren_targ = 1'b1;
        end
    end
    else begin // We are in SYNC state
        n_wren_targ = 1'b1;

        // check to see if we have finished:
        if (addr_targ == ABUF_NUM_ADDR - 1) begin
            // we are on the last write
            n_state = IDLE;         // next cycle, we switch to IDLE state
            n_done = 1'b1;          // assert done signal after this cycle
            n_wren_targ = 1'b0;     // stop writing after this cycle
            abuf_counter_en = 1'b0; // stop counting to prevent address-out-of-bounds
            // The counters are cleared once we switch to IDLE
        end
        else begin
            // keep sending the next address to read from abuf, until all are read
            abuf_counter_en = !(addr_abuf == ABUF_NUM_ADDR - 1);

            // as soon as the first write data is ready from src, we enable the delayed counter
            if (addr_abuf >= 4) begin
                wr_delay_counter_en = 1'b1;
            end
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        //reset state and control signals
        state <= IDLE;
        done <= 0;
        //addr_src <= 'b0;
        wren_targ <= 1'b0;
    end
    else begin
        // update state
        state <= n_state;
        done <= n_done;

        // update address registers
        //addr_src <= rddata_abuf; DO THIS COMBINATIONALLY

        // update write data registers
        //wrdata_targ <= rddata_src;

        // update write-enables:
        wren_targ <= n_wren_targ;
    end
end

endmodule : indirect_sync_writer
