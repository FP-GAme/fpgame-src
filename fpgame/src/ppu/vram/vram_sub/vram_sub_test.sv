module vram_sub_test (
    input logic clk,
    vram_if i
);

tile_ram_tester tilram (
    .clock(clk),
    .address_a(i.tilram_addr_a),
    .address_b(i.tilram_addr_b),
    .byteena_b(i.tilram_byteena_b),
    .data_a(   i.tilram_wrdata_a),
    .data_b(   i.tilram_wrdata_b),
    .wren_a(   i.tilram_wren_a),
    .wren_b(   i.tilram_wren_b),
    .q_a(      i.tilram_rddata_a),
    .q_b(      i.tilram_rddata_b)
);
pattern_ram_tester patram (
    .clock(clk),
    .address_a(i.patram_addr_a),
    .address_b(i.patram_addr_b),
    .byteena_b(i.patram_byteena_b),
    .data_a(   i.patram_wrdata_a),
    .data_b(   i.patram_wrdata_b),
    .wren_a(   i.patram_wren_a),
    .wren_b(   i.patram_wren_b),
    .q_a(      i.patram_rddata_a),
    .q_b(      i.patram_rddata_b)
);
palette_ram_tester palram (
    .clock(clk),
    .address_a(i.palram_addr_a),
    .address_b(i.palram_addr_b),
    .byteena_b(i.palram_byteena_b),
    .data_a(   i.palram_wrdata_a),
    .data_b(   i.palram_wrdata_b),
    .wren_a(   i.palram_wren_a),
    .wren_b(   i.palram_wren_b),
    .q_a(      i.palram_rddata_a),
    .q_b(      i.palram_rddata_b)
);
sprite_ram_tester sprram (
    .clock(clk),
    .address_a(i.sprram_addr_a),
    .address_b(i.sprram_addr_b),
    .byteena_b(i.sprram_byteena_b),
    .data_a(   i.sprram_wrdata_a),
    .data_b(   i.sprram_wrdata_b),
    .wren_a(   i.sprram_wren_a),
    .wren_b(   i.sprram_wren_b),
    .q_a(      i.sprram_rddata_a),
    .q_b(      i.sprram_rddata_b)
);

endmodule : vram_sub_test

