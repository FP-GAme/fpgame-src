`timescale 1ns/1ns

module indirect_sync_writer_tb;

    logic clk;
    logic rst_n;
    logic sync;
    logic done;

    // Abuf would be the tileng_rowdata_tilram
    logic [5:0]  addr_abuf;
    logic [15:0] rddata_abuf;

    // SRC would be the pattern RAM
    logic [63:0] rddata_src;
    logic [11:0] addr_src;

    // TARG would be the tileng_rowdata_patram
    logic [5:0]  addr_targ;
    logic [63:0] wrdata_targ;
    logic        wren_targ;

    // extracted signals
    logic [11:0]  rddata_abuf_extracted;
    // Normally should be {rddata_abuf[15:6], whatever is given by current row + scroll_y};
    // However, the way the testbench .hex files were set up, this is easier to verify:
    //assign rddata_abuf_extracted = {rddata_abuf[9:0], 2'b0}; // This extracts address to SRC
    assign rddata_abuf_extracted = {2'b0, rddata_abuf[9:0]};

    indirect_sync_writer dut (
        .clk,
        .rst_n,
        .sync,
        .done,
        .addr_abuf,
        .rddata_abuf(rddata_abuf_extracted),
        .addr_src,
        .wren_src(), // Our test RAM is a ROM, so it always reads.
        .rddata_src,
        .addr_targ,
        .wrdata_targ(wrdata_targ),
        .wren_targ
    );

    // Our addr_buf
    // Only use port B for address buf
    isw_tb_tileng_rowdata_tilram abuf (
        .address_a('X), // ignore port a
        .address_b(addr_abuf),
        .clock(clk),
        .data_a('X),   // ignore port a
        .data_b('0),   // Do not write. Only read
        .wren_a(1'b0), // ignore port a
        .wren_b(1'b0), // Only read
        .q_a(),
        .q_b(rddata_abuf)
    );

    // Our SRC
    isw_tb_pattern_ram src (
        .address(addr_src),
        .clock(clk),
        .q(rddata_src)
    );

    // Our TARGET
    tileng_rowdata_patram targ (
        .address_a(addr_targ), // TODO 6-bit. Ensure the correct attachment
        .address_b('X),        // This is Pixel-Mixer Facing. Not needed for sync_writer
        .clock(clk),
        .data_a(wrdata_targ),
        .data_b('X),           // Pixel-Mixer Facing
        .wren_a(wren_targ),
        .wren_b(1'b0),
        .q_a(),
        .q_b()
    );

    // 50MHz clock
    always begin
        clk = 1;
        #10;
        clk = 0;
        #10;
    end
    
    initial begin
        sync = 0;

        rst_n = 0;
        #1;
        rst_n = 1;
        #1;

        #20;
        sync = 1;
        #20;
        sync = 0;

        #1000;
        $stop;
    end
endmodule : indirect_sync_writer_tb