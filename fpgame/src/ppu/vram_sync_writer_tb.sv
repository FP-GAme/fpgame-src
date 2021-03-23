`timescale 1ns/1ns

module vram_sync_writer_tb;
    logic clk;
    logic rst_n;
    logic sync;
    logic done;

    logic [21:0]  tilram_a_addr;
    logic [1:0]   tilram_a_wren;
    logic [127:0] tilram_a_rddata;
    logic [23:0]  patram_a_addr;
    logic [1:0]   patram_a_wren;
    logic [127:0] patram_a_rddata;
    logic [17:0]  palram_a_addr;
    logic [1:0]   palram_a_wren;
    logic [127:0] palram_a_rddata;
    logic [11:0]  sprram_a_addr;
    logic [1:0]   sprram_a_wren;
    logic [127:0] sprram_a_rddata;
    logic [21:0]  tilram_b_addr;
    logic [7:0]   tilram_b_byteena;
    logic [127:0] tilram_b_wrdata;
    logic [1:0]   tilram_b_wren;
    logic [23:0]  patram_b_addr;
    logic [7:0]   patram_b_byteena;
    logic [127:0] patram_b_wrdata;
    logic [1:0]   patram_b_wren;
    logic [17:0]  palram_b_addr;
    logic [7:0]   palram_b_byteena;
    logic [127:0] palram_b_wrdata;
    logic [1:0]   palram_b_wren;
    logic [11:0]  sprram_b_addr;
    logic [7:0]   sprram_b_byteena;
    logic [127:0] sprram_b_wrdata;
    logic [1:0]   sprram_b_wren;

    vram_sync_writer dut (.*);

    tile_ram_tester tr1 (
        .address_a(tilram_a_addr[10:0]),
        .address_b(tilram_a_addr[21:11]),
        .byteena_b(8'b0),
        .clock(clk),
        .data_a(),
        .data_b(),
        .wren_a(tilram_a_wren[0]),
        .wren_b(tilram_a_wren[1]),
        .q_a(tilram_a_rddata[63:0]),
        .q_b(tilram_a_rddata[127:64])
    );
    tile_ram tr2 (
        .address_a(tilram_b_addr[10:0]),
        .address_b(tilram_b_addr[21:11]),
        .byteena_b(tilram_b_byteena),
        .clock(clk),
        .data_a(tilram_b_wrdata[63:0]),
        .data_b(tilram_b_wrdata[127:64]),
        .wren_a(tilram_b_wren[0]),
        .wren_b(tilram_b_wren[1]),
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
        #5;
        rst_n = 1;
        #10;

        sync = 1;
        #20;
        sync = 0;

        //#81960;
        #82000;
        $stop;
    end

endmodule : vram_sync_writer_tb
