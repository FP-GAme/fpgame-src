module ppu (
    input logic clk,
    input logic rst_n,

    // to HDMI video output
    output logic [9:0] rram_rddata,
    input logic  [8:0] rram_rdaddr,
    output logic [31:0] pram_rddata,
    input logic  [9:0] pram_rdaddr
);

    row_ram rr (
        .address_a(rram_rdaddr),
        .address_b(9'b0),
        .clock(clk),
        .data_a(10'b0), // TODO Change
        .data_b(10'b0), // TODO Change
        .wren_a(1'b0), // TODO Change
        .wren_b(1'b0), // TODO Change
        .q_a(rram_rddata),
        .q_b()
    );

    palette_ram pr (
        .address_a(pram_rdaddr),
        .address_b(10'b0), // TODO Change
        .clock(clk),
        .data_a(32'b0), // TODO Change
        .data_b(32'b0), // TODO Change
        .wren_a(1'b0), // TODO Change
        .wren_b(1'b0), //  TODO Change
        .q_a(pram_rddata),
        .q_b() // TODO Change
    );

endmodule : ppu
