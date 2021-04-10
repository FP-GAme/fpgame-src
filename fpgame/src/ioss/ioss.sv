module ioss (
    input  logic        clk,
    input  logic        rst_n,
    inout  logic [35:0] GPIO,
    output logic [15:0] con_state,
    output logic [31:0] scroll // TODO: Remove once demo is over
);

    logic con_serial, con_clock, con_latch;
    assign GPIO[8] = con_clock;
    assign GPIO[6] = con_latch;
    assign con_serial = GPIO[4];

    snes_controller ctrl (
        .con_serial,
        .clock(clk),
        .reset(rst_n),
        .con_clock,
        .con_latch,
        .con_state
    );

    scrolling_demo sd ( // TODO: Remove once demo is over
        .clk,
        .rst_n,
        .con_state,
        .scroll
    );

endmodule : ioss
