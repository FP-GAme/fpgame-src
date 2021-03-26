module vram (
    input logic clk,
    input logic rst_n,

    // these following interfaces are inputs (see src modport in vram_if)
    vram_if.src vram_ifP_src, // PPU uses vram_P
    vram_if.src vram_ifC_src  // CPU uses vram_C
);

    // PPU-Facing VRAM
    vram_sub vram_P (
        .clk,
        .i_src(vram_ifP_src)
    );

    // CPU-Facing VRAM
    vram_sub vram_C (
        .clk,
        .i_src(vram_ifC_src)
    );

endmodule : vram
