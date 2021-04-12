
module fpgame_soc (
	apu_buf_export_valid,
	apu_buf_export_data,
	apu_control_export_valid,
	apu_control_export_data,
	clk_clk,
	dma_engine_src_addr,
	dma_engine_start,
	dma_engine_finish,
	f2h_irq0_irq,
	h2f_vram_wraddr,
	h2f_vram_wren,
	h2f_vram_wrdata,
	hps_io_hps_io_sdio_inst_CMD,
	hps_io_hps_io_sdio_inst_D0,
	hps_io_hps_io_sdio_inst_D1,
	hps_io_hps_io_sdio_inst_CLK,
	hps_io_hps_io_sdio_inst_D2,
	hps_io_hps_io_sdio_inst_D3,
	hps_io_hps_io_usb1_inst_D0,
	hps_io_hps_io_usb1_inst_D1,
	hps_io_hps_io_usb1_inst_D2,
	hps_io_hps_io_usb1_inst_D3,
	hps_io_hps_io_usb1_inst_D4,
	hps_io_hps_io_usb1_inst_D5,
	hps_io_hps_io_usb1_inst_D6,
	hps_io_hps_io_usb1_inst_D7,
	hps_io_hps_io_usb1_inst_CLK,
	hps_io_hps_io_usb1_inst_STP,
	hps_io_hps_io_usb1_inst_DIR,
	hps_io_hps_io_usb1_inst_NXT,
	hps_io_hps_io_uart0_inst_RX,
	hps_io_hps_io_uart0_inst_TX,
	input_pio_export,
	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,
	ppu_bgcolor_export,
	ppu_bgscroll_export,
	ppu_enable_export,
	ppu_fgscroll_export,
	vramsrcaddrpio_rddata,
	vramsrcaddrpio_update_avail,
	vramsrcaddrpio_read_rst);	

	output		apu_buf_export_valid;
	output	[31:0]	apu_buf_export_data;
	output		apu_control_export_valid;
	output	[31:0]	apu_control_export_data;
	input		clk_clk;
	input	[31:0]	dma_engine_src_addr;
	input		dma_engine_start;
	output		dma_engine_finish;
	input	[31:0]	f2h_irq0_irq;
	output	[11:0]	h2f_vram_wraddr;
	output		h2f_vram_wren;
	output	[127:0]	h2f_vram_wrdata;
	inout		hps_io_hps_io_sdio_inst_CMD;
	inout		hps_io_hps_io_sdio_inst_D0;
	inout		hps_io_hps_io_sdio_inst_D1;
	output		hps_io_hps_io_sdio_inst_CLK;
	inout		hps_io_hps_io_sdio_inst_D2;
	inout		hps_io_hps_io_sdio_inst_D3;
	inout		hps_io_hps_io_usb1_inst_D0;
	inout		hps_io_hps_io_usb1_inst_D1;
	inout		hps_io_hps_io_usb1_inst_D2;
	inout		hps_io_hps_io_usb1_inst_D3;
	inout		hps_io_hps_io_usb1_inst_D4;
	inout		hps_io_hps_io_usb1_inst_D5;
	inout		hps_io_hps_io_usb1_inst_D6;
	inout		hps_io_hps_io_usb1_inst_D7;
	input		hps_io_hps_io_usb1_inst_CLK;
	output		hps_io_hps_io_usb1_inst_STP;
	input		hps_io_hps_io_usb1_inst_DIR;
	input		hps_io_hps_io_usb1_inst_NXT;
	input		hps_io_hps_io_uart0_inst_RX;
	output		hps_io_hps_io_uart0_inst_TX;
	input	[15:0]	input_pio_export;
	output	[14:0]	memory_mem_a;
	output	[2:0]	memory_mem_ba;
	output		memory_mem_ck;
	output		memory_mem_ck_n;
	output		memory_mem_cke;
	output		memory_mem_cs_n;
	output		memory_mem_ras_n;
	output		memory_mem_cas_n;
	output		memory_mem_we_n;
	output		memory_mem_reset_n;
	inout	[31:0]	memory_mem_dq;
	inout	[3:0]	memory_mem_dqs;
	inout	[3:0]	memory_mem_dqs_n;
	output		memory_mem_odt;
	output	[3:0]	memory_mem_dm;
	input		memory_oct_rzqin;
	output	[23:0]	ppu_bgcolor_export;
	output	[31:0]	ppu_bgscroll_export;
	output	[2:0]	ppu_enable_export;
	output	[31:0]	ppu_fgscroll_export;
	output	[31:0]	vramsrcaddrpio_rddata;
	output		vramsrcaddrpio_update_avail;
	input		vramsrcaddrpio_read_rst;
endmodule
