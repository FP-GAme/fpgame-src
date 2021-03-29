module fpgame (
    //////////// CLOCK //////////
    input         FPGA_CLK1_50,
    input         FPGA_CLK2_50,
    input         FPGA_CLK3_50,

    //////////// HDMI //////////
    inout         HDMI_I2C_SCL,
    inout         HDMI_I2C_SDA,
    inout         HDMI_I2S,
    inout         HDMI_LRCLK,
    inout         HDMI_MCLK,
    inout         HDMI_SCLK,
    output        HDMI_TX_CLK,
    output        HDMI_TX_DE,
    output [23:0] HDMI_TX_D,
    output        HDMI_TX_HS,
    input         HDMI_TX_INT,
    output        HDMI_TX_VS,

    //////////// HPS //////////
    inout         HPS_CONV_USB_N,
    output [14:0] HPS_DDR3_ADDR,
    output [2:0]  HPS_DDR3_BA,
    output        HPS_DDR3_CAS_N,
    output        HPS_DDR3_CKE,
    output        HPS_DDR3_CK_N,
    output        HPS_DDR3_CK_P,
    output        HPS_DDR3_CS_N,
    output [3:0]  HPS_DDR3_DM,
    inout  [31:0] HPS_DDR3_DQ,
    inout  [3:0]  HPS_DDR3_DQS_N,
    inout  [3:0]  HPS_DDR3_DQS_P,
    output        HPS_DDR3_ODT,
    output        HPS_DDR3_RAS_N,
    output        HPS_DDR3_RESET_N,
    input         HPS_DDR3_RZQ,
    output        HPS_DDR3_WE_N,
    output        HPS_ENET_GTX_CLK,
    inout         HPS_ENET_INT_N,
    output        HPS_ENET_MDC,
    inout         HPS_ENET_MDIO,
    input         HPS_ENET_RX_CLK,
    input  [3:0]  HPS_ENET_RX_DATA,
    input         HPS_ENET_RX_DV,
    output [3:0]  HPS_ENET_TX_DATA,
    output        HPS_ENET_TX_EN,
    inout         HPS_GSENSOR_INT,
    inout         HPS_I2C0_SCLK,
    inout         HPS_I2C0_SDAT,
    inout         HPS_I2C1_SCLK,
    inout         HPS_I2C1_SDAT,
    inout         HPS_KEY,
    inout         HPS_LED,
    inout         HPS_LTC_GPIO,
    output        HPS_SD_CLK,
    inout         HPS_SD_CMD,
    inout  [3:0]  HPS_SD_DATA,
    output        HPS_SPIM_CLK,
    input         HPS_SPIM_MISO,
    output        HPS_SPIM_MOSI,
    inout         HPS_SPIM_SS,
    input         HPS_UART_RX,
    output        HPS_UART_TX,
    input         HPS_USB_CLKOUT,
    inout  [7:0]  HPS_USB_DATA,
    input         HPS_USB_DIR,
    input         HPS_USB_NXT,
    output        HPS_USB_STP,

    //////////// GPIO_1, GPIO connect to GPIO Default //////////
    inout  [35:0] GPIO,
    output [7:0]  LED
);


// ====================
// === Interconnect ===
// ====================
// System resets
logic audio_rst_n, video_rst_n;
logic sys_rst_n; // Reset which releases after both video and audio PLLs are finished
assign sys_rst_n = audio_rst_n & video_rst_n;

logic audio_clk, video_clk;

// hdmi_generator to ppu interconnect
logic [9:0]  rowram_rddata;
logic [8:0]  rowram_rdaddr;
logic [63:0] palram_rddata;
logic [8:0]  palram_rdaddr;
logic        rowram_swap;
logic        vblank_start;
logic        vblank_end;

// ppu to cpu interconnect
logic [12:0] h2f_vram_wraddr;
logic        h2f_vram_wren;
logic [63:0] h2f_vram_wrdata;
logic [7:0]  h2f_vram_byteena;
logic        cpu_vram_wr_irq;
logic        cpu_wr_busy;

// cpu to ioss interconnect
logic [15:0] con_state;

// ==================
// === Submodules ===
// ==================
fpgame_soc u0 (
    .clk_clk                            (FPGA_CLK1_50),
    .h2f_vram_interface_export_wraddr   (h2f_vram_wraddr),
    .h2f_vram_interface_export_wren     (h2f_vram_wren),
    .h2f_vram_interface_export_wrdata   (h2f_vram_wrdata),
    .h2f_vram_interface_export_byteena  (h2f_vram_byteena),
    .hps_io_hps_io_sdio_inst_CMD        (HPS_SD_CMD),
    .hps_io_hps_io_sdio_inst_D0         (HPS_SD_DATA[0]),
    .hps_io_hps_io_sdio_inst_D1         (HPS_SD_DATA[1]),
    .hps_io_hps_io_sdio_inst_CLK        (HPS_SD_CLK),
    .hps_io_hps_io_sdio_inst_D2         (HPS_SD_DATA[2]),
    .hps_io_hps_io_sdio_inst_D3         (HPS_SD_DATA[3]),
    .hps_io_hps_io_usb1_inst_D0         (HPS_USB_DATA[0]),
    .hps_io_hps_io_usb1_inst_D1         (HPS_USB_DATA[1]),
    .hps_io_hps_io_usb1_inst_D2         (HPS_USB_DATA[2]),
    .hps_io_hps_io_usb1_inst_D3         (HPS_USB_DATA[3]),
    .hps_io_hps_io_usb1_inst_D4         (HPS_USB_DATA[4]),
    .hps_io_hps_io_usb1_inst_D5         (HPS_USB_DATA[5]),
    .hps_io_hps_io_usb1_inst_D6         (HPS_USB_DATA[6]),
    .hps_io_hps_io_usb1_inst_D7         (HPS_USB_DATA[7]),
    .hps_io_hps_io_usb1_inst_CLK        (HPS_USB_CLKOUT),
    .hps_io_hps_io_usb1_inst_STP        (HPS_USB_STP),
    .hps_io_hps_io_usb1_inst_DIR        (HPS_USB_DIR),
    .hps_io_hps_io_usb1_inst_NXT        (HPS_USB_NXT),
    .hps_io_hps_io_uart0_inst_RX        (HPS_UART_RX),
    .hps_io_hps_io_uart0_inst_TX        (HPS_UART_TX),
    .input_pio_export                   (con_state),
    .memory_mem_a                       (HPS_DDR3_ADDR),
    .memory_mem_ba                      (HPS_DDR3_BA),
    .memory_mem_ck                      (HPS_DDR3_CK_P),
    .memory_mem_ck_n                    (HPS_DDR3_CK_N),
    .memory_mem_cke                     (HPS_DDR3_CKE),
    .memory_mem_cs_n                    (HPS_DDR3_CS_N),
    .memory_mem_ras_n                   (HPS_DDR3_RAS_N),
    .memory_mem_cas_n                   (HPS_DDR3_CAS_N),
    .memory_mem_we_n                    (HPS_DDR3_WE_N),
    .memory_mem_reset_n                 (HPS_DDR3_RESET_N),
    .memory_mem_dq                      (HPS_DDR3_DQ),
    .memory_mem_dqs                     (HPS_DDR3_DQS_P),
    .memory_mem_dqs_n                   (HPS_DDR3_DQS_N),
    .memory_mem_odt                     (HPS_DDR3_ODT),
    .memory_mem_dm                      (HPS_DDR3_DM),
    .memory_oct_rzqin                   (HPS_DDR3_RZQ),
    .h2f_vram_interface_cpu_vram_wr_irq (cpu_vram_wr_irq),
    .cpu_wr_busy_export                 (cpu_wr_busy)
);

i2s_pll ipll (
    .refclk(FPGA_CLK1_50),
    .rst(0), // TODO: Tie to a physical or CPU-related reset
    .outclk_0(audio_clk),
    .locked(audio_rst_n)
);

vga_pll vpll (
    .refclk(FPGA_CLK1_50),
    .rst(0), // TODO: Tie to a physical or CPU-related reset
    .outclk_0(video_clk),
    .locked(video_rst_n)
);

hdmi_generator hgen (
    .audio_clk,
    .video_clk,
    .clk(FPGA_CLK1_50),
    .rst_n(sys_rst_n),
    .vga_pclk(HDMI_TX_CLK),
    .vga_de(HDMI_TX_DE),
    .vga_hs(HDMI_TX_HS),
    .vga_vs(HDMI_TX_VS),
    .vga_rgb(HDMI_TX_D),
    .i2c_sclk(HDMI_I2C_SCL),
    .i2c_sda(HDMI_I2C_SDA),
    .hdmi_tx_int(HDMI_TX_INT),
    .i2s_sclk(HDMI_SCLK),
    .i2s_lrclk(HDMI_LRCLK),
    .i2s_sda(HDMI_I2S),
    .rowram_rddata,
    .rowram_rdaddr,
    .palram_rddata,
    .palram_rdaddr,
    .rowram_swap,
    .vblank_start,
    .vblank_end
);

ppu u_ppu (
    .clk(FPGA_CLK1_50),
    .rst_n(sys_rst_n),
    .rowram_rddata,
    .rowram_rdaddr,
    .palram_rddata,
    .palram_rdaddr,
    .rowram_swap,
    .vblank_start,
    .vblank_end,
    .h2f_vram_wraddr,
    .h2f_vram_wren,
    .h2f_vram_wrdata,
    .h2f_vram_byteena,
    .cpu_vram_wr_irq,
    .cpu_wr_busy,
    .LED(LED[5:0])
);

ioss u_ioss (
    .clk(FPGA_CLK1_50),
    .rst_n(sys_rst_n),
    .GPIO,
    .LED(LED[7:6]),
    .con_state
);

endmodule : fpgame