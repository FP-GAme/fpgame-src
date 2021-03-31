module up_counter #(
    WIDTH = 8
) (
    input  logic clk,
    input  logic rst_n, // Async reset
    input  logic clr,   // Sync reset (clear)
    input  logic en,
    output logic [WIDTH-1:0] count
);

    localparam [WIDTH-1:0] one = { {(WIDTH-1){1'b0}}, 1'b1 };

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;            
        end
        else begin
            if (clr) begin
                count <= '0;
            end
            else begin
               count <= (en) ? count + one : count;
            end
        end
    end

endmodule : up_counter