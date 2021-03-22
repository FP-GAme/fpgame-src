module h2f_vram_interface (
    input  logic [12:0] avs_s0_address,    // avs_s0.address
    input  logic        avs_s0_write,      // .write
    input  logic [63:0] avs_s0_writedata,  // .writedata
    input  logic [7:0]  avs_s0_byteenable, // .byteenable
    input  logic        clock_clk,         // clock.clk
    input  logic        reset_reset,       // reset.reset
    output logic        ins_irq0_irq,      // ins_irq0.irq

    // ppu conduit
    output logic [12:0] coe_hps_vram_wraddr,
    output logic        coe_hps_vram_wren,
    output logic [63:0] coe_hps_vram_wrdata,
    output logic [7:0]  coe_hps_vram_byteena
);

    assign ins_irq0_irq = 1'b0;
    assign coe_hps_vram_wraddr = avs_s0_address;
    assign coe_hps_vram_wren = avs_s0_write;
    assign coe_hps_vram_wrdata = avs_s0_writedata;
    assign coe_hps_vram_byteena = avs_s0_byteenable;

endmodule : h2f_vram_interface
