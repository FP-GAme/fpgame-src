module vram_wr_selector (

    // from h2f bus writer
    input  logic [12:0] h2f_vram_wraddr,
    input  logic        h2f_vram_wren,
    input  logic [63:0] h2f_vram_wrdata,
    input  logic [7:0]  h2f_vram_byteena

    // from vram_sync 1 writer

    // from vram_sync 2 writer
);

    // 0x0000 Tile Start
    // 0x4000 Pattern Start
    // 0xC000 Palette Start
    // 0xD000 Sprite Start

    // Route


    /*
    * This module takes in all of the write-data lines and routes them.
    */

endmodule : vram_wr_selector
