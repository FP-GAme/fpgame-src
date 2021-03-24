interface vram_if;

    logic [10:0] tilram_addr_a;
    logic [10:0] tilram_addr_b;
    logic [7:0]  tilram_byteena_b;
    logic [63:0] tilram_wrdata_a;
    logic [63:0] tilram_wrdata_b;
    logic        tilram_wren_a;
    logic        tilram_wren_b;
    logic [63:0] tilram_rddata_a;
    logic [63:0] tilram_rddata_b;

    logic [11:0] patram_addr_a;
    logic [11:0] patram_addr_b;
    logic [7:0]  patram_byteena_b;
    logic [63:0] patram_wrdata_a;
    logic [63:0] patram_wrdata_b;
    logic        patram_wren_a;
    logic        patram_wren_b;
    logic [63:0] patram_rddata_a;
    logic [63:0] patram_rddata_b;

    logic [8:0]  palram_addr_a;
    logic [8:0]  palram_addr_b;
    logic [7:0]  palram_byteena_b;
    logic [63:0] palram_wrdata_a;
    logic [63:0] palram_wrdata_b;
    logic        palram_wren_a;
    logic        palram_wren_b;
    logic [63:0] palram_rddata_a;
    logic [63:0] palram_rddata_b;

    logic [5:0]  sprram_addr_a;
    logic [5:0]  sprram_addr_b;
    logic [7:0]  sprram_byteena_b;
    logic [63:0] sprram_wrdata_a;
    logic [63:0] sprram_wrdata_b;
    logic        sprram_wren_a;
    logic        sprram_wren_b;
    logic [63:0] sprram_rddata_a;
    logic [63:0] sprram_rddata_b;

endinterface
