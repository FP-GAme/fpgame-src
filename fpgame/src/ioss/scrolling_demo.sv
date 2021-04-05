module scrolling_demo (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] con_state,
    output logic [31:0] scroll
);

    // TODO: It looks like con_state holds the reverse of typical SNES controller state
    // TODO: See here: https://gamefaqs.gamespot.com/snes/916396-super-nintendo/faqs/5395
    localparam [3:0] UP    = 4'd11;
    localparam [3:0] DOWN  = 4'd10;
    localparam [3:0] LEFT  = 4'd9;
    localparam [3:0] RIGHT = 4'd8;

    logic [8:0] scroll_x;
    logic [8:0] scroll_y;

    logic v_inc_en;
    logic v_dec_en;
    logic h_inc_en;
    logic h_dec_en;

    assign scroll = {7'b0, scroll_y, 7'b0, scroll_x};

    timer #(.PERIOD(6250000)) ut (
        .clock(clk),
        .reset(!con_state[UP]),
        .tick(v_inc_en)
    );
    timer #(.PERIOD(6250000)) dt (
        .clock(clk),
        .reset(!con_state[DOWN]),
        .tick(v_dec_en)
    );
    timer #(.PERIOD(6250000)) lt (
        .clock(clk),
        .reset(!con_state[LEFT]),
        .tick(h_dec_en)
    );
    timer #(.PERIOD(6250000)) rt (
        .clock(clk),
        .reset(!con_state[RIGHT]),
        .tick(h_inc_en)
    );

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            scroll_x <= 8'b0;
            scroll_y <= 8'b0;
        end
        else begin
            if (v_inc_en) scroll_y <= scroll_y - 9'b1;
            else if (v_dec_en) scroll_y <= scroll_y + 9'b1;
            if (h_inc_en) scroll_x <= scroll_x + 9'b1;
            else if (h_dec_en) scroll_x <= scroll_x - 9'b1;
        end
    end

endmodule : scrolling_demo