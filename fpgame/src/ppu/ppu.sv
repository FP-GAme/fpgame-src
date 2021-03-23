module ppu (
    input logic clk,
    input logic rst_n,

    // to HDMI video output
    output logic [9:0]  rowram_rddata,
    input  logic [8:0]  rowram_rdaddr,
    output logic [63:0] palram_rddata,
    input  logic [8:0]  palram_rdaddr,

    // h2f_vram_avalon_interface
    input  logic [12:0] h2f_vram_wraddr,
    input  logic        h2f_vram_wren,
    input  logic [63:0] h2f_vram_wrdata,
    input  logic [7:0]  h2f_vram_byteena
);

    row_ram rr (
        .address_a(rowram_rdaddr),
        .address_b(9'b0),
        .clock(clk),
        .data_a(10'b0), // TODO Change
        .data_b(10'b0), // TODO Change
        .wren_a(1'b0), // TODO Change
        .wren_b(1'b0), // TODO Change
        .q_a(rowram_rddata),
        .q_b()
    );

    // VRAM 1
    tile_ram tr1 (
        .address_a(),
        .address_b(),
        .byteena_b(),
        .clock(clk),
        .data_a(),
        .data_b(),
        .wren_a(),
        .wren_b(),
        .q_a(),
        .q_b()
        //input  [10:0] address_a;
        //input  [10:0] address_b;
        //input  [7:0]  byteena_b;
        //input         clock;
        //input  [63:0] data_a;
        //input  [63:0] data_b;
        //input         wren_a;
        //input         wren_b;
        //output [63:0] q_a;
        //output [63:0] q_b;
    );
    pattern_ram ptr1 (
        .address_a(),
        .address_b(),
        .byteena_b(),
        .clock(clk),
        .data_a(),
        .data_b(),
        .wren_a(),
        .wren_b(),
        .q_a(),
        .q_b()
        //input  [11:0] address_a;
        //input  [11:0] address_b;
        //input  [7:0]  byteena_b;
        //input         clock;
        //input  [63:0] data_a;
        //input  [63:0] data_b;
        //input         wren_a;
        //input         wren_b;
        //output [63:0] q_a;
        //output [63:0] q_b;
    );
    palette_ram plr1 (
        .address_a(palram_rdaddr),
        .address_b(9'b0), // TODO Change
        .byteena_b(8'b0),
        .clock(clk),
        .data_a(64'b0), // TODO Change
        .data_b(64'b0), // TODO Change
        .wren_a(1'b0), // TODO Change
        .wren_b(1'b0), //  TODO Change
        .q_a(palram_rddata),
        .q_b() // TODO Change
    );
    sprite_ram sr1 (
        .address_a(),
        .address_b(),
        .byteena_b(),
        .clock(clk),
        .data_a(),
        .data_b(),
        .wren_a(),
        .wren_b(),
        .q_a(),
        .q_b()
        //input  [5:0] address_a;
        //input  [5:0] address_b;
        //input  [7:0]  byteena_b;
        //input         clock;
        //input  [63:0] data_a;
        //input  [63:0] data_b;
        //input         wren_a;
        //input         wren_b;
        //output [63:0] q_a;
        //output [63:0] q_b;
    );
    
    // VRAM 2
    //tile_ram tr2 (
    //
    //);
    //pattern_ram ptr2 (
    //
    //);
    /*palette_ram plr2 (
        .address_a(palram_rdaddr),
        .address_b(10'b0), // TODO Change
        .clock(clk),
        .data_a(32'b0), // TODO Change
        .data_b(32'b0), // TODO Change
        .wren_a(1'b0), // TODO Change
        .wren_b(1'b0), //  TODO Change
        .q_a(palram_rddata),
        .q_b() // TODO Change
    );*/
    //sprite_ram sr2 (
    //
    //);

endmodule : ppu
