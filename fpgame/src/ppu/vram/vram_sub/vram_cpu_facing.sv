/* vram_cpu_facing.sv
 * Implements the CPU-Facing VRAM, featuring 2 128-bit ports for use with the SDRAM DMA-Engine.
 */

module vram_cpu_facing (
    input logic clk,
    vram_if_cpu_facing.src i_src
);

tile_ram_cpu_facing tilram (
    .clock(clk),
    .address_a(i_src.tilram_addr_a),
    .address_b(i_src.tilram_addr_b),
    .data_a(   i_src.tilram_wrdata_a),
    .data_b(   i_src.tilram_wrdata_b),
    .wren_a(   i_src.tilram_wren_a),
    .wren_b(   i_src.tilram_wren_b),
    .q_a(      i_src.tilram_rddata_a),
    .q_b(      i_src.tilram_rddata_b)
);
pattern_ram_cpu_facing patram (
    .clock(clk),
    .address_a(i_src.patram_addr_a),
    .address_b(i_src.patram_addr_b),
    .data_a(   i_src.patram_wrdata_a),
    .data_b(   i_src.patram_wrdata_b),
    .wren_a(   i_src.patram_wren_a),
    .wren_b(   i_src.patram_wren_b),
    .q_a(      i_src.patram_rddata_a),
    .q_b(      i_src.patram_rddata_b)
);
palette_ram_cpu_facing palram (
    .clock(clk),
    .address_a(i_src.palram_addr_a),
    .address_b(i_src.palram_addr_b),
    .data_a(   i_src.palram_wrdata_a),
    .data_b(   i_src.palram_wrdata_b),
    .wren_a(   i_src.palram_wren_a),
    .wren_b(   i_src.palram_wren_b),
    .q_a(      i_src.palram_rddata_a),
    .q_b(      i_src.palram_rddata_b)
);
sprite_ram_cpu_facing sprram (
    .clock(clk),
    .address_a(i_src.sprram_addr_a),
    .address_b(i_src.sprram_addr_b),
    .data_a(   i_src.sprram_wrdata_a),
    .data_b(   i_src.sprram_wrdata_b),
    .wren_a(   i_src.sprram_wren_a),
    .wren_b(   i_src.sprram_wren_b),
    .q_a(      i_src.sprram_rddata_a),
    .q_b(      i_src.sprram_rddata_b)
);

endmodule : vram_cpu_facing