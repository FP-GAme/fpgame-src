/* sync_writer.sv
 * Upon receiveing the sync signal, reads from a source memory and writes to a destination memory,
 *   effectively synchronizing the contents.
 * Tweak the read/write data widths (which must be identical), using the DATA_WIDTH parameter.
 * The addressable area and area copied are controlled by ADDR_WIDTH and MAX_ADDR respectively.
 * Note, MAX_ADDR must be < 2^ADDR_WIDTH.
 */

module sync_writer #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 11,
    parameter MAX_ADDR = 2047
) (
    // control signals
    input  logic clk,
    input  logic rst_n,
    input  logic sync,
    output logic done,
    input  logic clr_done,

    // from (source)
    output logic [ADDR_WIDTH-1:0]   addr_from,
    output logic                    wren_from,
    input  logic [DATA_WIDTH-1:0]   rddata_from,

    // to (destination)
    output logic [ADDR_WIDTH-1:0]   addr_to,
    output logic [DATA_WIDTH/8-1:0] byteena_to,
    output logic [DATA_WIDTH-1:0]   wrdata_to,
    output logic                    wren_to
);

enum { IDLE, SYNC } state;

// Need to delay the wr address due to the 1 cycle read latency
logic [ADDR_WIDTH-1:0] addr_to_buf;

localparam [ADDR_WIDTH-1:0] one = { {(ADDR_WIDTH-1){1'b0}}, 1'b1 };

assign wrdata_to = rddata_from;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        //reset state and control signals
        state <= IDLE;
        done <= 0;

        addr_from <= 'b0; // read address
        wren_from <= 1'b0;
        addr_to <= 'b0; // write address
        addr_to_buf <= 'b0; // write address delay buffer
        byteena_to <= 'b0;
        wren_to <= 1'b0;
    end
    else begin
        unique case (state)
            IDLE: begin
                // Do nothing, unless sync occurs
                if (sync) begin
                    // set all controls and start sync process
                    done <= 0;
                    state <= SYNC;

                    // start by reading from 0th address
                    addr_from <= 'b0;
                    addr_to <= 'b0;
                    addr_to_buf <= 'b0;
                    
                    // read from RAM A
                    wren_from <= 1'b0;

                    // write to RAM B
                    byteena_to <= '1; // Fill with 1s to enable writing of all bytes
                    wren_to <= 1'b1;
                end
                else if (clr_done) done <= 1'b0;
            end
            SYNC: begin
                // if all writes are done, exit to idle and assert sync signal
                if (addr_to == MAX_ADDR) begin
                    done <= 1;
                    wren_to <= 1'b0;
                    state <= IDLE;
                end
                else begin

                    // to prevent memory out-of-bound access, ensure addr_from wraps back to 0
                    if (addr_from == MAX_ADDR) addr_from <= 'b0;
                    else addr_from <= addr_from + one; // send the next read command to RAM A

                    // prepare to write to the old read address (from RAM A) in RAM B
                    addr_to_buf <= addr_from;
                    addr_to <= addr_to_buf;
                end
            end
        endcase
    end
end


endmodule : sync_writer
