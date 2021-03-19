module hdmi_generator (
    input logic audio_clk,
    input logic video_clk,
    input logic clk,
    input logic rst_n,

    output logic vga_pclk,
    output logic vga_de,
    output logic vga_hs,
    output logic vga_vs,
    output logic [23:0] vga_rgb,

    output i2c_sclk,
    inout i2c_sda,
	 input hdmi_tx_int,

    output logic i2s_sclk,
    output logic i2s_lrclk,
    output logic i2s_sda
);

vpg u_vpg (
    .clk_50(clk),
	 .video_clk(video_clk),
    .reset_n(rst_n),
    .vpg_pclk(vga_pclk),
    .vpg_de(vga_de),
    .vpg_hs(vga_hs),
    .vpg_vs(vga_vs),
    .vpg_r(vga_rgb[23:16]),
    .vpg_g(vga_rgb[15:8]),
    .vpg_b(vga_rgb[7:0])
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
