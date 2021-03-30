module dbuf_ppu_ctrl_regs (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sync,
    input  logic [31:0] ppu_bgscroll,
    input  logic [2:0]  ppu_enable,
    input  logic [23:0] ppu_bgcolor,
    input  logic [31:0] ppu_fgscroll,
    output logic [31:0] dbuf_bgscroll,
    output logic [2:0]  dbuf_enable,
    output logic [23:0] dbuf_bgcolor,
    output logic [31:0] dbuf_fgscroll
);

    // TODO: Implement

endmodule : dbuf_ppu_ctrl_regs