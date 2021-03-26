`timescale 1ns/1ns

module vram_sync_writer_tb;
    logic clk;
    logic rst_n;
    logic sync;
    logic done;

    vram_if vram_ifP();
    vram_if vram_ifC();

    vram_sync_writer dut (
        .clk,
        .rst_n,
        .sync,
        .done,
        .vram_ifP_usr(vram_ifP.usr),
        .vram_ifC_usr(vram_ifC.usr)
    );

    vram_test vram_dut (
        .clk,
        .rst_n,
        .swap(1'b0),
        .vram_ifP_src(vram_ifP.src),
        .vram_ifC_src(vram_ifC.src)
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

        #41040
        sync = 1;
        #20;
        sync = 0;

        #40940;
        $stop;
    end

endmodule : vram_sync_writer_tb
