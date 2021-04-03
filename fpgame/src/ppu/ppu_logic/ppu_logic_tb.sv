`timescale 1ns/1ns

module ppu_logic_tb;

    logic clk;
    logic rst_n;

    // Controls for this testbench (from/to HDMI video output)
    logic [8:0] hdmi_rowram_rdaddr; // tied to 0. We don't use.
    logic [8:0] hdmi_palram_rdaddr; // also tied to 0. We don't use
    logic       rowram_swap;        // Essentially the "start" signal
    logic [7:0] next_row;           // Which row to prepare?

    assign hdmi_rowram_rdaddr = 9'b0;
    assign hdmi_palram_rdaddr = 9'b0;

    vram_if vram_ppu_ifP(); // VRAM interface used by ppu_logic

    vram_sub_test vr (
        .clk,
        .i_src(vram_ppu_ifP.src) // PPU-Logic-Facing VRAM
    );

    ppu_logic dut (
        .clk,
        .rst_n,
        .hdmi_rowram_rddata(), // leave disconnected, since hdmi_video_output isn't part of the sim
        .hdmi_rowram_rdaddr,
        .hdmi_palram_rddata(), // also leave disconnected
        .hdmi_palram_rdaddr,
        .rowram_swap,
        .next_row,
        .vram_ppu_ifP_usr(vram_ppu_ifP.usr)
    );

    // 50MHz clock
    always begin
        clk = 1;
        #10;
        clk = 0;
        #10;
    end
    
    initial begin
        rowram_swap = 1'b0;
        next_row = 8'b0;

        rst_n = 0;
        #1;
        rst_n = 1;
        #19;

        rowram_swap = 1'b1;
        #20;
        rowram_swap = 1'b0;
        #64000;

/*
        rowram_swap = 1'b1;
        #20;
        rowram_swap = 1'b0;
        #3200;
*/
        $stop;
    end

endmodule : ppu_logic_tb