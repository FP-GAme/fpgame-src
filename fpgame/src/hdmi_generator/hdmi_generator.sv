module hdmi_generator (
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

    // to PPU
    input  logic [9:0]  hdmi_rowram_rddata,
    output logic [8:0]  hdmi_rowram_rdaddr,
    input  logic [23:0] hdmi_color_rddata,
    output logic [9:0]  hdmi_color_rdaddr,
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
    .color_rddata(hdmi_color_rddata),
    .color_rdaddr(hdmi_color_rdaddr),
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

endmodule : hdmi_generator
