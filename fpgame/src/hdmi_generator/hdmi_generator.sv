module hdmi_generator (
    input logic audio_clk,
    input logic video_clk,
    input logic clk,
    input logic rst_n,

    // to top
    output logic vga_pclk,
    output logic vga_de,
    output logic vga_hs,
    output logic vga_vs,
    output logic [23:0] vga_rgb,

    output logic i2c_sclk,
    inout wire i2c_sda,
    input logic hdmi_tx_int,

    output logic i2s_sclk,
    output logic i2s_lrclk,
    output logic i2s_sda,

    // to PPU
    input  logic [9:0]  hdmi_rowram_rddata,
    output logic [8:0]  hdmi_rowram_rdaddr,
    input  logic [63:0] hdmi_palram_rddata,
    output logic [8:0]  hdmi_palram_rdaddr,
    output logic        rowram_swap,  // Also acts as a start-writing signal
    output logic        vblank_start, // Acts as a vram sync signal
    output logic        vblank_end_soon, // Tells the PPU when to start preparing the next row RAM
    output logic [7:0]  next_row

);

hdmi_video_output hvo (
    .video_clk(video_clk),
    .rst_n(rst_n),
    .vga_pclk(vga_pclk),
    .vga_de(vga_de),
    .vga_hs(vga_hs),
    .vga_vs(vga_vs),
    .vga_rgb(vga_rgb),
    .rowram_rddata(hdmi_rowram_rddata),
    .rowram_rdaddr(hdmi_rowram_rdaddr),
    .palram_rddata(hdmi_palram_rddata),
    .palram_rdaddr(hdmi_palram_rdaddr),
    .rowram_swap,
    .vblank_start,
    .vblank_end_soon,
    .next_row
);

I2C_HDMI_Config u_I2C_HDMI_Config (
    .iCLK(clk),
    .iRST_N(rst_n),
    .I2C_SCLK(i2c_sclk),
    .I2C_SDAT(i2c_sda),
    .HDMI_TX_INT(hdmi_tx_int)
);

AUDIO_IF u_AVG (
    .audio_clk(audio_clk),
    .rst_n(rst_n),
    .sclk(i2s_sclk),
    .lrclk(i2s_lrclk),
    .i2s(i2s_sda)
);

endmodule : hdmi_generator