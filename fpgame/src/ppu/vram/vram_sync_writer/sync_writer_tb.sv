`timescale 1ns/1ns

module sync_writer_tb;
    logic clk;
    logic rst_n;
    logic sync;
    logic done;

    // FROM
    logic [10:0] tilram_a_addr_a;
    logic        tilram_a_wren_a;
    logic [63:0] tilram_a_rddata_a;
    logic [10:0] tilram_a_addr_b;
    logic        tilram_a_wren_b;
    logic [63:0] tilram_a_rddata_b;

    // TO
    logic [10:0] tilram_b_addr_a;
    logic [63:0] tilram_b_wrdata_a;
    logic        tilram_b_wren_a;
    logic [10:0] tilram_b_addr_b;
    logic [7:0]  tilram_b_byteena_b;
    logic [63:0] tilram_b_wrdata_b;
    logic        tilram_b_wren_b;

    sync_writer dut (
        .clk,
        .rst_n,
        .sync,
        .done,
        .addr_from(tilram_a_addr_a),
        .wren_from(tilram_a_wren_a),
        .rddata_from(tilram_a_rddata_a),
        .addr_to(tilram_b_addr_b),
        .byteena_to(tilram_b_byteena_b),
        .wrdata_to(tilram_b_wrdata_b),
        .wren_to(tilram_b_wren_b)
    );

    tile_ram_tester tr1 (
        .address_a(tilram_a_addr_a),
        .address_b(tilram_a_addr_b),
        .byteena_b(8'hFF),
        .clock(clk),
        .data_a(64'b0),
        .data_b(64'b0),
        .wren_a(tilram_a_wren_a),
        .wren_b(tilram_a_wren_b),
        .q_a(tilram_a_rddata_a),
        .q_b(tilram_a_rddata_b)
    );
    tile_ram tr2 (
        .address_a(tilram_b_addr_a),
        .address_b(tilram_b_addr_b),
        .byteena_b(tilram_b_byteena_b),
        .clock(clk),
        .data_a(tilram_b_wrdata_a),
        .data_b(tilram_b_wrdata_b),
        .wren_a(tilram_b_wren_a),
        .wren_b(tilram_b_wren_b),
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
        #20;
        rst_n = 1;
        #20;

        sync = 1;
        #20;
        sync = 0;

        #82000;
        $stop;
    end

endmodule : sync_writer_tb
