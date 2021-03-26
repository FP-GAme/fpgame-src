module vram_sub_test (
    input logic clk,
    vram_if.src i_src
);

tile_ram_tester tilram (
    .clock(clk),
    .address_a(i_src.tilram_addr_a),
    .address_b(i_src.tilram_addr_b),
    .byteena_b(i_src.tilram_byteena_b),
    .data_a(   i_src.tilram_wrdata_a),
    .data_b(   i_src.tilram_wrdata_b),
    .wren_a(   i_src.tilram_wren_a),
    .wren_b(   i_src.tilram_wren_b),
    .q_a(      i_src.tilram_rddata_a),
    .q_b(      i_src.tilram_rddata_b)
);
pattern_ram_tester patram (
    .clock(clk),
    .address_a(i_src.patram_addr_a),
    .address_b(i_src.patram_addr_b),
    .byteena_b(i_src.patram_byteena_b),
    .data_a(   i_src.patram_wrdata_a),
    .data_b(   i_src.patram_wrdata_b),
    .wren_a(   i_src.patram_wren_a),
    .wren_b(   i_src.patram_wren_b),
    .q_a(      i_src.patram_rddata_a),
    .q_b(      i_src.patram_rddata_b)
);
palette_ram_tester palram (
    .clock(clk),
    .address_a(i_src.palram_addr_a),
    .address_b(i_src.palram_addr_b),
    .byteena_b(i_src.palram_byteena_b),
    .data_a(   i_src.palram_wrdata_a),
    .data_b(   i_src.palram_wrdata_b),
    .wren_a(   i_src.palram_wren_a),
    .wren_b(   i_src.palram_wren_b),
    .q_a(      i_src.palram_rddata_a),
    .q_b(      i_src.palram_rddata_b)
);
sprite_ram_tester sprram (
    .clock(clk),
    .address_a(i_src.sprram_addr_a),
    .address_b(i_src.sprram_addr_b),
    .byteena_b(i_src.sprram_byteena_b),
    .data_a(   i_src.sprram_wrdata_a),
    .data_b(   i_src.sprram_wrdata_b),
    .wren_a(   i_src.sprram_wren_a),
    .wren_b(   i_src.sprram_wren_b),
    .q_a(      i_src.sprram_rddata_a),
    .q_b(      i_src.sprram_rddata_b)
);

endmodule : vram_sub_test

