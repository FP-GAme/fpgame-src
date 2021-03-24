module vram_sync_writer (
    input  logic clk,
    input  logic rst_n,
    input  logic sync,
    output logic done,

    // All of the following signals are concatenations of both ports of a dual-port memory
    // from vram a
    output logic [21:0]  tilram_a_addr,
    output logic [1:0]   tilram_a_wren,
    input  logic [127:0] tilram_a_rddata,

    output logic [23:0]  patram_a_addr,
    output logic [1:0]   patram_a_wren,
    input  logic [127:0] patram_a_rddata,

    output logic [17:0]  palram_a_addr,
    output logic [1:0]   palram_a_wren,
    input  logic [127:0] palram_a_rddata,

    output logic [11:0]  sprram_a_addr,
    output logic [1:0]   sprram_a_wren,
    input  logic [127:0] sprram_a_rddata,

    // to vram b
    output logic [21:0]  tilram_b_addr,
    output logic [7:0]   tilram_b_byteena,
    output logic [127:0] tilram_b_wrdata,
    output logic [1:0]   tilram_b_wren,

    output logic [23:0]  patram_b_addr,
    output logic [7:0]   patram_b_byteena,
    output logic [127:0] patram_b_wrdata,
    output logic [1:0]   patram_b_wren,

    output logic [17:0]  palram_b_addr,
    output logic [7:0]   palram_b_byteena,
    output logic [127:0] palram_b_wrdata,
    output logic [1:0]   palram_b_wren,

    output logic [11:0]  sprram_b_addr,
    output logic [7:0]   sprram_b_byteena,
    output logic [127:0] sprram_b_wrdata,
    output logic [1:0]   sprram_b_wren
);

// We always sync from VRAM A to VRAM B. The PPU will take care of routing the signals so that the
// newly swapped RAM is VRAM A.

enum { IDLE, SYNC } state;

logic [11:0] rd_addr;
logic [11:0] wr_addr;
logic tilram_done, patram_done, palram_done, sprram_done;

parameter [11:0] tilram_max_addr = 12'd2047;
parameter [11:0] patram_max_addr = 12'd4095;
parameter [11:0] palram_max_addr = 12'd511;
parameter [11:0] sprram_max_addr = 12'd39;


//assign tilram_a_addr = {1'b1, rd_addr[9:0], 1'b0, rd_addr[9:0]};
// assign tilram_a_addr = {rd_addr[10:0] << 11, rd_addr[10:0]};
assign tilram_a_addr = {1'b0, 10'b0, 1'b0, rd_addr[9:0]};
assign tilram_b_addr = {1'b0, 10'b0, 1'b0, wr_addr[9:0]};
assign tilram_b_wrdata = tilram_a_rddata;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        //reset state and control signals
        state <= IDLE;
        rd_addr <= 0;
        wr_addr <= 0;
        {tilram_done, patram_done, palram_done, sprram_done} <= 4'b0;

        // VRAM A read control signals should be set to 0
        //tilram_a_addr <= 22'b0;
        tilram_a_wren <= 2'b0;
        //patram_a_addr <= 24'b0;
        patram_a_wren <= 2'b0;
        //palram_a_addr <= 18'b0;
        palram_a_wren <= 2'b0;
        //sprram_a_addr <= 12'b0;
        sprram_a_wren <= 2'b0;

        // Stop writes to VRAM B
        {tilram_b_wren, patram_b_wren, palram_b_wren, sprram_b_wren} <= 8'b0;
    end
    else begin
        unique case (state)
            IDLE: begin
                if (sync) begin
                    // set all controls and start sync process:
                    rd_addr <= 0;
                    wr_addr <= 0;
                    {tilram_done, patram_done, palram_done, sprram_done} <= 4'b0;
                    {tilram_a_wren, patram_b_wren, palram_b_wren, sprram_b_wren} <= 8'b0;
                    {tilram_b_wren, patram_b_wren, palram_b_wren, sprram_b_wren} <= 8'hFF;
                    tilram_b_byteena <= 8'hFF;

                    state <= SYNC;
                end
                else begin
                    state <= IDLE;
                end

                // VRAM A read control signals should be set to 0
                //tilram_a_addr <= 22'b0;
                //tilram_a_wren <= 2'b0;
                //patram_a_addr <= 24'b0;
                //patram_a_wren <= 2'b0;
                //palram_a_addr <= 18'b0;
                //palram_a_wren <= 2'b0;
                //sprram_a_addr <= 12'b0;
                //sprram_a_wren <= 2'b0;

                // VRAM B should not be written to
                //tilram_b_addr <= 22'b0;
                //tilram_b_byteena <= 8'b0;
                //tilram_b_wrdata <= 128'b0;
                //tilram_b_wren <= 2'b0;

                //patram_b_addr <= 24'b0;
                //patram_b_byteena <= 8'b0;
                //patram_b_wrdata <= 128'b0;
                //patram_b_wren <= 2'b0;

                //palram_b_addr <= 18'b0;
                //palram_b_byteena <= 8'b0;
                //palram_b_wrdata <= 128'b0;
                //palram_b_wren <= 2'b0;

                //sprram_b_addr <= 12'b0;
                //sprram_b_byteena <= 8'b0;
                //sprram_b_wrdata <= 128'b0;
                //sprram_b_wren <= 2'b0;
            end
            SYNC: begin
                if (wr_addr >= tilram_max_addr>>1) begin
                    tilram_b_wren <= 2'b00; //stop writing
                    tilram_done <= 1;
                    // read from VRAM A
                    // Combinational now tilram_a_addr <= {rd_addr[10:0], rd_addr[10:0]};

                    // write resulting data to VRAM B
                    // Combinational now tilram_b_addr <= tilram_a_addr{11'b0, wr_addr_count[10:0]}; //{wr_addr_count[, wr_addr_count[10:0]};
                    //tilram_b_byteena <= 8'hFF;
                    //tilram_b_wren <= 2'b11;
                end
                /*
                if (wr_addr_count < patram_max_addr) begin
                    // read from VRAM A
                    patram_a_addr <= {rd_addr_count, rd_addr_count};
                    patram_a_wren <= 2'b00;

                    // write resulting data to VRAM B
                    patram_b_addr <= {wr_addr_count, wr_addr_count};
                    patram_b_byteena <= 8'hFF;
                    patram_b_wrdata <= patram_a_rddata;
                    patram_b_wren <= 2'b11;
                end
                else begin
                    patram_b_wren <= 2'b00; //stop writing
                    patram_done <= 1;
                end
                if (wr_addr_count < palram_max_addr) begin
                    // read from VRAM A
                    palram_a_addr <= {rd_addr_count[8:0], rd_addr_count[8:0]};
                    palram_a_wren <= 2'b00;

                    // write resulting data to VRAM B
                    palram_b_addr <= {wr_addr_count[8:0], wr_addr_count[8:0]};
                    palram_b_byteena <= 8'hFF;
                    palram_b_wrdata <= palram_a_rddata;
                    palram_b_wren <= 2'b11;
                end
                else begin
                    palram_b_wren <= 2'b00; //stop writing
                    palram_done <= 1;
                end
                if (wr_addr_count < sprram_max_addr) begin
                    // read from VRAM A
                    sprram_a_addr <= {rd_addr_count[5:0], rd_addr_count[5:0]};
                    sprram_a_wren <= 2'b00;

                    // write resulting data to VRAM B
                    sprram_b_addr <= {wr_addr_count[5:0], wr_addr_count[5:0]};
                    sprram_b_byteena <= 8'hFF;
                    sprram_b_wrdata <= sprram_a_rddata;
                    sprram_b_wren <= 2'b11;
                end
                else begin
                    sprram_b_wren <= 2'b00; //stop writing
                    sprram_done <= 1;
                end */

                // if all writes are done, exit to idle and assert sync signal
                if (tilram_done & patram_done & palram_done & sprram_done) begin
                    done <= 1;
                    state <= IDLE;
                end
                else begin
                    rd_addr <= rd_addr + 12'b1;
                    wr_addr <= rd_addr;
                end
            end
        endcase
    end
end

endmodule : vram_sync_writer
