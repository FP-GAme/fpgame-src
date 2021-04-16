module dbuf_ppu_ctrl_regs (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sync,
    input  logic [31:0] ppu_bgscroll,
    input  logic [31:0] ppu_fgscroll,
    input  logic [2:0]  ppu_enable,
    input  logic [23:0] ppu_bgcolor,
    output logic [31:0] dbuf_bgscroll,
    output logic [31:0] dbuf_fgscroll,
    output logic [2:0]  dbuf_enable,
    output logic [23:0] dbuf_bgcolor
);

    // Only update control registers on sync
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            dbuf_bgscroll <= 32'b0;
            dbuf_fgscroll <= 32'b0;
            dbuf_enable   <=  3'b0;
            dbuf_bgcolor  <= 24'b0;
        end
        else begin
            dbuf_bgscroll <= (sync) ? ppu_bgscroll : dbuf_bgscroll;
            dbuf_fgscroll <= (sync) ? ppu_fgscroll : dbuf_fgscroll;
            dbuf_enable   <= (sync) ? ppu_enable   : dbuf_enable;
            dbuf_bgcolor  <= (sync) ? ppu_bgcolor  : dbuf_bgcolor;
        end
    end

endmodule : dbuf_ppu_ctrl_regs