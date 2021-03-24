module vram_test (
    input logic clk,
    input logic rst_n,
    input logic swap,

    vram_if vram_ifP, // PPU uses vramP
    vram_if vram_ifC  // CPU uses vramC
);

    // swapped = 1 means vram1 is swapped with vram2.
    logic swapped;
    vram_if vram_sub_if1();
    vram_if vram_sub_if2();

    vram_sub vram1 (
        .clk,
        .i(vram_sub_if1)
    );

    vram_sub_test vram2 (
        .clk,
        .i(vram_sub_if2)
    );

    // By default (swapped = 0):
    // * VRAM_1_in  = VRAM_P_out
    // * VRAM_1_out = VRAM_P_in
    // * VRAM_2_in  = VRAM_C_out
    // * VRAM_2_out = VRAM_C_in
    // When swapped: (swapped = 1):
    // * VRAM_1_in  = VRAM_C_out
    // * VRAM_1_out = VRAM_C_in
    // * VRAM_2_in  = VRAM_P_out
    // * VRAM_2_out = VRAM_P_in

    // Apparently you cannot connect interfaces. Thanks SystemVerilog...
    // Ugly mux logic incoming...
    // vram1 inputs
    assign vram_sub_if1.tilram_addr_a    = (swapped) ? vram_ifC.tilram_addr_a    : vram_ifP.tilram_addr_a;
    assign vram_sub_if1.tilram_addr_b    = (swapped) ? vram_ifC.tilram_addr_b    : vram_ifP.tilram_addr_b;
    assign vram_sub_if1.tilram_byteena_b = (swapped) ? vram_ifC.tilram_byteena_b : vram_ifP.tilram_byteena_b;
    assign vram_sub_if1.tilram_wrdata_a  = (swapped) ? vram_ifC.tilram_wrdata_a  : vram_ifP.tilram_wrdata_a;
    assign vram_sub_if1.tilram_wrdata_b  = (swapped) ? vram_ifC.tilram_wrdata_b  : vram_ifP.tilram_wrdata_b;
    assign vram_sub_if1.tilram_wren_a    = (swapped) ? vram_ifC.tilram_wren_a    : vram_ifP.tilram_wren_a;
    assign vram_sub_if1.tilram_wren_b    = (swapped) ? vram_ifC.tilram_wren_b    : vram_ifP.tilram_wren_b;
    assign vram_sub_if1.patram_addr_a    = (swapped) ? vram_ifC.patram_addr_a    : vram_ifP.patram_addr_a;
    assign vram_sub_if1.patram_addr_b    = (swapped) ? vram_ifC.patram_addr_b    : vram_ifP.patram_addr_b;
    assign vram_sub_if1.patram_byteena_b = (swapped) ? vram_ifC.patram_byteena_b : vram_ifP.patram_byteena_b;
    assign vram_sub_if1.patram_wrdata_a  = (swapped) ? vram_ifC.patram_wrdata_a  : vram_ifP.patram_wrdata_a;
    assign vram_sub_if1.patram_wrdata_b  = (swapped) ? vram_ifC.patram_wrdata_b  : vram_ifP.patram_wrdata_b;
    assign vram_sub_if1.patram_wren_a    = (swapped) ? vram_ifC.patram_wren_a    : vram_ifP.patram_wren_a;
    assign vram_sub_if1.patram_wren_b    = (swapped) ? vram_ifC.patram_wren_b    : vram_ifP.patram_wren_b;
    assign vram_sub_if1.palram_addr_a    = (swapped) ? vram_ifC.palram_addr_a    : vram_ifP.palram_addr_a;
    assign vram_sub_if1.palram_addr_b    = (swapped) ? vram_ifC.palram_addr_b    : vram_ifP.palram_addr_b;
    assign vram_sub_if1.palram_byteena_b = (swapped) ? vram_ifC.palram_byteena_b : vram_ifP.palram_byteena_b;
    assign vram_sub_if1.palram_wrdata_a  = (swapped) ? vram_ifC.palram_wrdata_a  : vram_ifP.palram_wrdata_a;
    assign vram_sub_if1.palram_wrdata_b  = (swapped) ? vram_ifC.palram_wrdata_b  : vram_ifP.palram_wrdata_b;
    assign vram_sub_if1.palram_wren_a    = (swapped) ? vram_ifC.palram_wren_a    : vram_ifP.palram_wren_a;
    assign vram_sub_if1.palram_wren_b    = (swapped) ? vram_ifC.palram_wren_b    : vram_ifP.palram_wren_b;
    assign vram_sub_if1.sprram_addr_a    = (swapped) ? vram_ifC.sprram_addr_a    : vram_ifP.sprram_addr_a;
    assign vram_sub_if1.sprram_addr_b    = (swapped) ? vram_ifC.sprram_addr_b    : vram_ifP.sprram_addr_b;
    assign vram_sub_if1.sprram_byteena_b = (swapped) ? vram_ifC.sprram_byteena_b : vram_ifP.sprram_byteena_b;
    assign vram_sub_if1.sprram_wrdata_a  = (swapped) ? vram_ifC.sprram_wrdata_a  : vram_ifP.sprram_wrdata_a;
    assign vram_sub_if1.sprram_wrdata_b  = (swapped) ? vram_ifC.sprram_wrdata_b  : vram_ifP.sprram_wrdata_b;
    assign vram_sub_if1.sprram_wren_a    = (swapped) ? vram_ifC.sprram_wren_a    : vram_ifP.sprram_wren_a;
    assign vram_sub_if1.sprram_wren_b    = (swapped) ? vram_ifC.sprram_wren_b    : vram_ifP.sprram_wren_b;

    // vram2 inputs
    assign vram_sub_if2.tilram_addr_a    = (swapped) ? vram_ifP.tilram_addr_a    : vram_ifC.tilram_addr_a;
    assign vram_sub_if2.tilram_addr_b    = (swapped) ? vram_ifP.tilram_addr_b    : vram_ifC.tilram_addr_b;
    assign vram_sub_if2.tilram_byteena_b = (swapped) ? vram_ifP.tilram_byteena_b : vram_ifC.tilram_byteena_b;
    assign vram_sub_if2.tilram_wrdata_a  = (swapped) ? vram_ifP.tilram_wrdata_a  : vram_ifC.tilram_wrdata_a;
    assign vram_sub_if2.tilram_wrdata_b  = (swapped) ? vram_ifP.tilram_wrdata_b  : vram_ifC.tilram_wrdata_b;
    assign vram_sub_if2.tilram_wren_a    = (swapped) ? vram_ifP.tilram_wren_a    : vram_ifC.tilram_wren_a;
    assign vram_sub_if2.tilram_wren_b    = (swapped) ? vram_ifP.tilram_wren_b    : vram_ifC.tilram_wren_b;
    assign vram_sub_if2.patram_addr_a    = (swapped) ? vram_ifP.patram_addr_a    : vram_ifC.patram_addr_a;
    assign vram_sub_if2.patram_addr_b    = (swapped) ? vram_ifP.patram_addr_b    : vram_ifC.patram_addr_b;
    assign vram_sub_if2.patram_byteena_b = (swapped) ? vram_ifP.patram_byteena_b : vram_ifC.patram_byteena_b;
    assign vram_sub_if2.patram_wrdata_a  = (swapped) ? vram_ifP.patram_wrdata_a  : vram_ifC.patram_wrdata_a;
    assign vram_sub_if2.patram_wrdata_b  = (swapped) ? vram_ifP.patram_wrdata_b  : vram_ifC.patram_wrdata_b;
    assign vram_sub_if2.patram_wren_a    = (swapped) ? vram_ifP.patram_wren_a    : vram_ifC.patram_wren_a;
    assign vram_sub_if2.patram_wren_b    = (swapped) ? vram_ifP.patram_wren_b    : vram_ifC.patram_wren_b;
    assign vram_sub_if2.palram_addr_a    = (swapped) ? vram_ifP.palram_addr_a    : vram_ifC.palram_addr_a;
    assign vram_sub_if2.palram_addr_b    = (swapped) ? vram_ifP.palram_addr_b    : vram_ifC.palram_addr_b;
    assign vram_sub_if2.palram_byteena_b = (swapped) ? vram_ifP.palram_byteena_b : vram_ifC.palram_byteena_b;
    assign vram_sub_if2.palram_wrdata_a  = (swapped) ? vram_ifP.palram_wrdata_a  : vram_ifC.palram_wrdata_a;
    assign vram_sub_if2.palram_wrdata_b  = (swapped) ? vram_ifP.palram_wrdata_b  : vram_ifC.palram_wrdata_b;
    assign vram_sub_if2.palram_wren_a    = (swapped) ? vram_ifP.palram_wren_a    : vram_ifC.palram_wren_a;
    assign vram_sub_if2.palram_wren_b    = (swapped) ? vram_ifP.palram_wren_b    : vram_ifC.palram_wren_b;
    assign vram_sub_if2.sprram_addr_a    = (swapped) ? vram_ifP.sprram_addr_a    : vram_ifC.sprram_addr_a;
    assign vram_sub_if2.sprram_addr_b    = (swapped) ? vram_ifP.sprram_addr_b    : vram_ifC.sprram_addr_b;
    assign vram_sub_if2.sprram_byteena_b = (swapped) ? vram_ifP.sprram_byteena_b : vram_ifC.sprram_byteena_b;
    assign vram_sub_if2.sprram_wrdata_a  = (swapped) ? vram_ifP.sprram_wrdata_a  : vram_ifC.sprram_wrdata_a;
    assign vram_sub_if2.sprram_wrdata_b  = (swapped) ? vram_ifP.sprram_wrdata_b  : vram_ifC.sprram_wrdata_b;
    assign vram_sub_if2.sprram_wren_a    = (swapped) ? vram_ifP.sprram_wren_a    : vram_ifC.sprram_wren_a;
    assign vram_sub_if2.sprram_wren_b    = (swapped) ? vram_ifP.sprram_wren_b    : vram_ifC.sprram_wren_b;

    // outputs to VRAM_P
    assign vram_ifP.tilram_rddata_a  = (swapped) ? vram_sub_if2.tilram_rddata_a  : vram_sub_if1.tilram_rddata_a;
    assign vram_ifP.tilram_rddata_b  = (swapped) ? vram_sub_if2.tilram_rddata_b  : vram_sub_if1.tilram_rddata_b;
    assign vram_ifP.patram_rddata_a  = (swapped) ? vram_sub_if2.patram_rddata_a  : vram_sub_if1.patram_rddata_a;
    assign vram_ifP.patram_rddata_b  = (swapped) ? vram_sub_if2.patram_rddata_b  : vram_sub_if1.patram_rddata_b;
    assign vram_ifP.palram_rddata_a  = (swapped) ? vram_sub_if2.palram_rddata_a  : vram_sub_if1.palram_rddata_a;
    assign vram_ifP.palram_rddata_b  = (swapped) ? vram_sub_if2.palram_rddata_b  : vram_sub_if1.palram_rddata_b;
    assign vram_ifP.sprram_rddata_a  = (swapped) ? vram_sub_if2.sprram_rddata_a  : vram_sub_if1.sprram_rddata_a;
    assign vram_ifP.sprram_rddata_b  = (swapped) ? vram_sub_if2.sprram_rddata_b  : vram_sub_if1.sprram_rddata_b;

    // outputs to VRAM_C
    assign vram_ifC.tilram_rddata_a  = (swapped) ? vram_sub_if1.tilram_rddata_a  : vram_sub_if2.tilram_rddata_a;
    assign vram_ifC.tilram_rddata_b  = (swapped) ? vram_sub_if1.tilram_rddata_b  : vram_sub_if2.tilram_rddata_b;
    assign vram_ifC.patram_rddata_a  = (swapped) ? vram_sub_if1.patram_rddata_a  : vram_sub_if2.patram_rddata_a;
    assign vram_ifC.patram_rddata_b  = (swapped) ? vram_sub_if1.patram_rddata_b  : vram_sub_if2.patram_rddata_b;
    assign vram_ifC.palram_rddata_a  = (swapped) ? vram_sub_if1.palram_rddata_a  : vram_sub_if2.palram_rddata_a;
    assign vram_ifC.palram_rddata_b  = (swapped) ? vram_sub_if1.palram_rddata_b  : vram_sub_if2.palram_rddata_b;
    assign vram_ifC.sprram_rddata_a  = (swapped) ? vram_sub_if1.sprram_rddata_a  : vram_sub_if2.sprram_rddata_a;
    assign vram_ifC.sprram_rddata_b  = (swapped) ? vram_sub_if1.sprram_rddata_b  : vram_sub_if2.sprram_rddata_b;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            swapped <= 0;
        end
        else begin
            if (swap) begin
                swapped <= ~swapped;
            end
        end
    end

endmodule : vram_test
