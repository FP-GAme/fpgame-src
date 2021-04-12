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

    // cpu to ioss interconnect
    logic [15:0] con_state;
    assign con_state = 16'd0;

    /* APU to CPU interconnect */
    logic [63:0] apu_mem_data;
    logic [31:0] apu_control, apu_buf;
    logic [28:0] apu_mem_addr;
    logic apu_control_valid, apu_buf_valid, apu_buf_irq;
    assign apu_buf_irq = 1'b0;


    // ==================
    // === Submodules ===
    // ==================
    fpgame_soc u0 (
        .clk_clk                            (clk),
        .hps_io_hps_io_sdio_inst_CMD        (),
        .hps_io_hps_io_sdio_inst_D0         (),
        .hps_io_hps_io_sdio_inst_D1         (),
        .hps_io_hps_io_sdio_inst_CLK        (),
        .hps_io_hps_io_sdio_inst_D2         (),
        .hps_io_hps_io_sdio_inst_D3         (),
        .hps_io_hps_io_usb1_inst_D0         (),
        .hps_io_hps_io_usb1_inst_D1         (),
        .hps_io_hps_io_usb1_inst_D2         (),
        .hps_io_hps_io_usb1_inst_D3         (),
        .hps_io_hps_io_usb1_inst_D4         (),
        .hps_io_hps_io_usb1_inst_D5         (),
        .hps_io_hps_io_usb1_inst_D6         (),
        .hps_io_hps_io_usb1_inst_D7         (),
        .hps_io_hps_io_usb1_inst_CLK        (),
        .hps_io_hps_io_usb1_inst_STP        (),
        .hps_io_hps_io_usb1_inst_DIR        (),
        .hps_io_hps_io_usb1_inst_NXT        (),
        .hps_io_hps_io_uart0_inst_RX        (),
        .hps_io_hps_io_uart0_inst_TX        (),
        .memory_mem_a                       (),
        .memory_mem_ba                      (),
        .memory_mem_ck                      (),
        .memory_mem_ck_n                    (),
        .memory_mem_cke                     (),
        .memory_mem_cs_n                    (),
        .memory_mem_ras_n                   (),
        .memory_mem_cas_n                   (),
        .memory_mem_we_n                    (),
        .memory_mem_reset_n                 (),
        .memory_mem_dq                      (),
        .memory_mem_dqs                     (),
        .memory_mem_dqs_n                   (),
        .memory_mem_odt                     (),
        .memory_mem_dm                      (),
        .memory_oct_rzqin                   (),
        // === CPU IRQ ===
        .f2h_irq0_irq                       ({ 30'd1, ppu_dma_rdy_irq, apu_buf_irq }),
        // === IOSS/CPU Communication ===
        .input_pio_export                   (con_state),
        // === APU/CPU Communication ===
        .apu_control_export_data		    (apu_control),
        .apu_control_export_valid           (apu_control_valid),
        .apu_buf_export_data                (apu_buf),
        .apu_buf_export_valid               (apu_buf_valid),
        // === PPU/CPU Communication ===
        .h2f_vram_wraddr                    (h2f_vram_wraddr),
        .h2f_vram_wren                      (h2f_vram_wren),
        .h2f_vram_wrdata                    (h2f_vram_wrdata),
        .ppu_bgscroll_export                (ppu_bgscroll),
        .ppu_fgscroll_export                (ppu_fgscroll),
        .ppu_enable_export                  (ppu_enable),
        .ppu_bgcolor_export                 (ppu_bgcolor),
        .dma_engine_src_addr                (dma_engine_src_addr),
        .dma_engine_start                   (dma_engine_start),
        .dma_engine_finish                  (dma_engine_finish),
        .vramsrcaddrpio_rddata              (vramsrcaddrpio_rddata),
        .vramsrcaddrpio_update_avail        (vramsrcaddrpio_update_avail),
        .vramsrcaddrpio_read_rst            (vramsrcaddrpio_update_avail)
    );

    hdmi_generator hgen (
        .video_clk,
        .clk(clk),
        .rst_n(sys_rst_n),
        .vga_pclk(HDMI_TX_CLK),
        .vga_de(HDMI_TX_DE),
        .vga_hs(HDMI_TX_HS),
        .vga_vs(HDMI_TX_VS),
        .vga_rgb(HDMI_TX_D),
        .i2c_sclk(HDMI_I2C_SCL),
        .i2c_sda(HDMI_I2C_SDA),
        .hdmi_tx_int(HDMI_TX_INT),
        .hdmi_rowram_rddata,
        .hdmi_rowram_rdaddr,
        .hdmi_palram_rddata,
        .hdmi_palram_rdaddr,
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
        sys_rst_n = 0;
        #1;
        sys_rst_n = 1;
        #1;

        #(16800000 * 2); // Simulate for 2 frames
        $stop;
    end

endmodule : fpgame_video_tb