`timescale 1ns/1ns

module hdmi_video_output_tb;

    // control signals
    logic video_clk;
    logic clk;
    logic rst_n;

    // output signals of interest
    logic [23:0] vga_rgb;
    logic vga_pclk;
    logic vga_de;
    logic vga_hs;
    logic vga_vs;
    logic rowram_swap;

    // interconnect
    logic [9:0] rowram_rddata;
    logic [8:0] rowram_rdaddr;
    logic [23:0] color_rddata;
    logic [9:0] color_rdaddr;


    hdmi_video_output hvo (
        .video_clk(video_clk),
        .rst_n(rst_n),
        .vga_pclk(vga_pclk),
        .vga_de(vga_de),
        .vga_hs(vga_hs),
        .vga_vs(vga_vs),
        .vga_rgb(vga_rgb),
        .rowram_rddata,
        .rowram_rdaddr,
        .color_rddata,
        .color_rdaddr,
        .rowram_swap
    );

    // test RAM
    row_ram rr (
        .address_a(rowram_rdaddr),
        .address_b(9'b0),
        .clock(clk),
        .data_a(10'b0), // TODO Change
        .data_b(10'b0), // TODO Change
        .wren_a(1'b0), // TODO Change
        .wren_b(1'b0), // TODO Change
        .q_a(rowram_rddata),
        .q_b()
    );

    // test RAM
    palette_ram pr (
        .address_a(palram_rdaddr),
        .address_b(9'b0), // TODO Change
        .byteena_b(8'b0),
        .clock(clk),
        .data_a(64'b0), // TODO Change
        .data_b(64'b0), // TODO Change
        .wren_a(1'b0), // TODO Change
        .wren_b(1'b0), //  TODO Change
        .q_a(palram_rddata),
        .q_b() // TODO Change
    );

    always begin
        clk = 1;
        #10;
        clk = 0;
        #10;
    end

    always begin
        video_clk = 1;
        #20;
        video_clk = 0;
        #20;
    end

    initial begin
        rst_n = 0;
        #1;
        rst_n = 1;
        #1;

        #16800020;
        $stop;
    end

endmodule : hdmi_video_output_tb
