module vram_test (
    input logic clk,
    input logic rst_n,

    vram_if.src vram_ifP_src, // PPU uses vram_P
    vram_if.src vram_ifC_src  // CPU uses vram_C
);

    // PPU-Facing VRAM
    vram_sub vram1 (
        .clk,
        .i_src(vram_ifP_src)
    );

    // CPU-Facing TEST VRAM. These are preinitialized for testing
    vram_sub_test vram2 (
        .clk,
        .i_src(vram_ifC_src)
    );

endmodule : vram_test
