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

    // from RAM A (source)
    output logic [ADDR_WIDTH-1:0]   addr_A,
    output logic                    wren_A,
    input  logic [DATA_WIDTH-1:0]   rddata_A,

    // to vram b
    output logic [ADDR_WIDTH-1:0]   addr_B,
    output logic [DATA_WIDTH/8-1:0] byteena_B,
    output logic [DATA_WIDTH-1:0]   wrdata_B,
    output logic                    wren_B
);

enum { IDLE, SYNC } state;

// Need to delay the wr address due to the 1 cycle read latency
logic [ADDR_WIDTH-1:0] addr_B_buf;

assign wrdata_B = rddata_A;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        //reset state and control signals
        state <= IDLE;
        done <= 0;

        addr_A <= 'b0; // read address
        wren_A <= 1'b0;
        addr_B <= 'b0; // write address
        addr_B_buf <= 'b0; // write address delay buffer
        byteena_B <= 'b0;
        wren_B <= 1'b0;
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
                    addr_A <= 'b0;
                    addr_B <= 'b0;
                    addr_B_buf <= 'b0;
                    
                    // read from RAM A
                    wren_A <= 1'b0;

                    // write to RAM B
                    byteena_B <= '1; // Fill with 1s to enable writing of all bytes
                    wren_B <= 1'b1;
                end
            end
            SYNC: begin
                // if all writes are done, exit to idle and assert sync signal
                if (addr_B == MAX_ADDR) begin
                    done <= 1;
                    wren_B <= 1'b0;
                    state <= IDLE;
                end
                else begin
                    // send the next read command to RAM A
                    addr_A <= addr_A + 'b1;
                    // prepare to write to the old read address (from RAM A) in RAM B
                    addr_B_buf <= addr_A;
                    addr_B <= addr_B_buf;
                end
            end
        endcase
    end
end


endmodule : sync_writer
