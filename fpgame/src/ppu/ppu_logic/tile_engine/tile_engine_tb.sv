`timescale 1ns/1ns
module tile_engine_tb;

    logic clk;
    logic rst_n;
    logic prep;
    logic done;
    logic [10:0] tilram_addr;
    logic [63:0] tilram_rddata;
    logic [11:0] patram_addr;
    logic [63:0] patram_rddata;
    logic [7:0]  pixel_data;

    tile_engine #(
        .FG(0)
    ) bgte (
        .clk,
        .rst_n,
        .next_row('0),
        .tilram_addr,
        .tilram_rddata,
        .patram_addr,
        .patram_rddata,
        .scroll('0),
        .enable(1'b1),
        .prep,
        .pixel_addr(9'd222),
        .pixel_data,
        .done
    );

    pattern_ram_tester patram_test (
        .address_a(patram_addr),
        .address_b('X),
        .byteena_b('X),
        .clock(clk),
        .data_a('X),
        .data_b('X),
        .wren_a(1'b0),
        .wren_b(1'b0),
        .q_a(patram_rddata),
        .q_b()
    );
    
    tile_ram_tester tilram_test (
        .address_a(tilram_addr),
        .address_b('X),
        .byteena_b('X),
        .clock(clk),
        .data_a('X),
        .data_b('X),
        .wren_a(1'b0),
        .wren_b(1'b0),
        .q_a(tilram_rddata),
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
        prep = 0;
        rst_n = 0;
        #1;
        rst_n = 1;
        #1;

        #20;
        prep = 1;
        #20;
        prep = 0;

        #3200;
        $stop;
    end
endmodule : tile_engine_tb