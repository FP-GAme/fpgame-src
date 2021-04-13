`timescale 1ns/1ns

module fpgame_video_tb;
    // ====================
    // === Interconnect ===
    // ====================
    logic clk;
    logic video_clk;
    logic sys_rst_n;

    // hdmi_generator to ppu interconnect
    logic [9:0]  hdmi_rowram_rddata;
    logic [8:0]  hdmi_rowram_rdaddr;
    logic [63:0] hdmi_palram_rddata;
    logic [8:0]  hdmi_palram_rdaddr;
    logic        rowram_swap;
    logic        vblank_start;
    logic        vblank_end_soon;
    logic [7:0]  next_row;

    // ppu to cpu interconnect
    logic [11:0]  h2f_vram_wraddr;
    logic         h2f_vram_wren;
    logic [127:0] h2f_vram_wrdata;
    logic [31:0]  vramsrcaddrpio_rddata;
    logic         vramsrcaddrpio_update_avail;
    logic         vramsrcaddrpio_read_rst;
    logic [31:0]  dma_engine_src_addr;
    logic         dma_engine_start;
    logic         dma_engine_finish;
    logic         ppu_dma_rdy_irq;
    logic [31:0]  ppu_bgscroll;
    logic [2:0]   ppu_enable;
    logic [23:0]  ppu_bgcolor;
    logic [31:0]  ppu_fgscroll;

    // "Don't-care" assignments for this testbench
    assign h2f_vram_wraddr = '0;
    assign h2f_vram_wren = 1'b0;
    assign h2f_vram_wrdata = '0;
    assign vramsrcaddrpio_rddata = '0;
    assign vramsrcaddrpio_update_avail = 1'b0;
    assign ppu_bgscroll = '0;
    assign ppu_enable = '0;
    assign ppu_bgcolor = '0;
    assign ppu_fgscroll = '0;
    assign hdmi_tx_int = 1'b0;

    // ==================
    // === Submodules ===
    // ==================
    hdmi_video_output hvo (
        .video_clk(video_clk),
        .rst_n(sys_rst_n),
        .vga_pclk(),
        .vga_de(),
        .vga_hs(),
        .vga_vs(),
        .vga_rgb(),
        .rowram_rddata(hdmi_rowram_rddata),
        .rowram_rdaddr(hdmi_rowram_rdaddr),
        .palram_rddata(hdmi_palram_rddata),
        .palram_rdaddr(hdmi_palram_rdaddr),
        .rowram_swap,
        .vblank_start,
        .vblank_end_soon,
        .next_row
    );

    ppu u_ppu (
        .clk(clk),
        .rst_n(sys_rst_n),
        .hdmi_rowram_rddata,
        .hdmi_rowram_rdaddr,
        .hdmi_palram_rddata,
        .hdmi_palram_rdaddr,
        .rowram_swap,
        .next_row,
        .vblank_start,
        .vblank_end_soon,
        .h2f_vram_wraddr,
        .h2f_vram_wren,
        .h2f_vram_wrdata,
        .bgscroll(ppu_bgscroll),
        .vramsrcaddrpio_rddata,
        .vramsrcaddrpio_update_avail,
        .vramsrcaddrpio_read_rst,
        .dma_engine_src_addr,
        .dma_engine_start,
        .dma_engine_finish,
        .ppu_dma_rdy_irq
    );

    // ==================
    // === Test Bench ===
    // ==================

    // 50 MHz FPGA clock
    always begin
        clk = 1;
        #10;
        clk = 0;
        #10;
    end

    // 25 MHz Video Clock (supposed to be PLL-generated)
    always begin
        video_clk = 1;
        #20;
        video_clk = 0;
        #20;
    end

    initial begin
        dma_engine_finish = 1'b0;

        sys_rst_n = 0;
        #1;
        sys_rst_n = 1;
        @(posedge clk);

        // === Simulation Start ===
        repeat (10) @(posedge clk);
        dma_engine_finish = 1'b1;
        @(posedge clk);
        dma_engine_finish = 1'b0;

        repeat (840000) @(posedge clk); // Simulate for a 1 frame

        $stop;
    end

endmodule : fpgame_video_tb