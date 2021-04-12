/* vram_if_cpu_facing.sv
 * Interface to the Dual-Port CPU-Facing VRAM
 */

interface vram_if_cpu_facing;

    logic [9:0]   tilram_addr_a;    // I
    logic [9:0]   tilram_addr_b;    // I 
    logic [127:0] tilram_wrdata_a;  // I
    logic [127:0] tilram_wrdata_b;  // I
    logic         tilram_wren_a;    // I
    logic         tilram_wren_b;    // I
    logic [127:0] tilram_rddata_a;  // O
    logic [127:0] tilram_rddata_b;  // O

    logic [10:0]  patram_addr_a;    // I
    logic [10:0]  patram_addr_b;    // I
    logic [127:0] patram_wrdata_a;  // I
    logic [127:0] patram_wrdata_b;  // I
    logic         patram_wren_a;    // I
    logic         patram_wren_b;    // I
    logic [127:0] patram_rddata_a;  // O
    logic [127:0] patram_rddata_b;  // O

    logic [7:0]   palram_addr_a;    // I
    logic [7:0]   palram_addr_b;    // I
    logic [127:0] palram_wrdata_a;  // I
    logic [127:0] palram_wrdata_b;  // I
    logic         palram_wren_a;    // I
    logic         palram_wren_b;    // I
    logic [127:0] palram_rddata_a;  // O
    logic [127:0] palram_rddata_b;  // O

    logic [4:0]   sprram_addr_a;    // I
    logic [4:0]   sprram_addr_b;    // I
    logic [127:0] sprram_wrdata_a;  // I
    logic [127:0] sprram_wrdata_b;  // I
    logic         sprram_wren_a;    // I
    logic         sprram_wren_b;    // I
    logic [127:0] sprram_rddata_a;  // O
    logic [127:0] sprram_rddata_b;  // O

    // Denotes an actual VRAM (or a source). E.g., vram.sv
    modport src (
        input  tilram_addr_a,    tilram_addr_b,
        input  tilram_wrdata_a,  tilram_wrdata_b,
        input  tilram_wren_a,    tilram_wren_b,
        output tilram_rddata_a,  tilram_rddata_b,

        input  patram_addr_a,    patram_addr_b,
        input  patram_wrdata_a,  patram_wrdata_b,
        input  patram_wren_a,    patram_wren_b,
        output patram_rddata_a,  patram_rddata_b,

        input  palram_addr_a,    palram_addr_b,
        input  palram_wrdata_a,  palram_wrdata_b,
        input  palram_wren_a,    palram_wren_b,
        output palram_rddata_a,  palram_rddata_b,

        input  sprram_addr_a,    sprram_addr_b,
        input  sprram_wrdata_a,  sprram_wrdata_b,
        input  sprram_wren_a,    sprram_wren_b,
        output sprram_rddata_a,  sprram_rddata_b
    );

    // Denotes a user which interacts with VRAM. E.g., vram_sync_writer.sv
    modport usr (
        output tilram_addr_a,    tilram_addr_b,
        output tilram_wrdata_a,  tilram_wrdata_b,
        output tilram_wren_a,    tilram_wren_b,
        input  tilram_rddata_a,  tilram_rddata_b,

        output patram_addr_a,    patram_addr_b,
        output patram_wrdata_a,  patram_wrdata_b,
        output patram_wren_a,    patram_wren_b,
        input  patram_rddata_a,  patram_rddata_b,

        output palram_addr_a,    palram_addr_b,
        output palram_wrdata_a,  palram_wrdata_b,
        output palram_wren_a,    palram_wren_b,
        input  palram_rddata_a,  palram_rddata_b,

        output sprram_addr_a,    sprram_addr_b,
        output sprram_wrdata_a,  sprram_wrdata_b,
        output sprram_wren_a,    sprram_wren_b,
        input  sprram_rddata_a,  sprram_rddata_b
    );

endinterface