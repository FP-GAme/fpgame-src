/* vram_interconnect.sv
 * Decides which of PPU, Sync-Writer, and CPU gets access to the PPU-Facing and CPU-Facing VRAMs.
 * Additionally, routes the incoming CPU's signals to one of the vram_sub modules (Tile Ram, Pattern
 *   RAM ... etc.) depending on the incoming address.
 */

module vram_interconnect (
    input  logic [12:0] h2f_vram_wraddr,
    input  logic        h2f_vram_wren,
    input  logic [63:0] h2f_vram_wrdata,
    input  logic [7:0]  h2f_vram_byteena,

    input  logic        sync_active,

    // inputs from other vram bus users
    vram_if.src vram_vsw_ifP_src,
    vram_if.src vram_vsw_ifC_src,
    vram_if.src vram_ppu_ifP_src,

    // final output to actual vram
    vram_if.usr vram_ifP_usr,
    vram_if.usr vram_ifC_usr
);

// Signals to demux from the full CPU write address (h2f_vram_wraddr):
// One set of these should be tied to h2f_vram_wraddr[whatever width:0] (chosen by the demux logic)
// The non-chosen buses can safely be left as Xs as long as wr_en is set to 0.
// TODO: Check if leaving addr lines are Xs is bad idea... It might be...
logic [10:0] cpu_tilram_wraddr;
logic [11:0] cpu_patram_wraddr;
logic [8:0]  cpu_palram_wraddr;
logic [5:0]  cpu_sprram_wraddr;
logic cpu_tilram_wren;
logic cpu_patram_wren;
logic cpu_palram_wren;
logic cpu_sprram_wren;
logic [63:0] cpu_tilram_wrdata;
logic [63:0] cpu_patram_wrdata;
logic [63:0] cpu_palram_wrdata;
logic [63:0] cpu_sprram_wrdata;
logic [7:0] cpu_tilram_byteena;
logic [7:0] cpu_patram_byteena;
logic [7:0] cpu_palram_byteena;
logic [7:0] cpu_sprram_byteena;

logic cpu_choose_patram, cpu_choose_palram, cpu_choose_sprram; // cpu_choose_tilram is the default

localparam [12:0] patram_start_addr = 13'h800;
localparam [12:0] palram_start_addr = 13'h1800;
localparam [12:0] sprram_start_addr = 13'h1A00;

// temporary variable for holding address subtraction results
logic [12:0] addr_translation;

// === CPU Write Bus Demux ===
always_comb begin
    /* Here is an overview of reasoning behind the demux logic.
     * Demux logic is based on which MSBs in the write address are 1s.
     *
     * Firstly, here are the max addresses in binary for each section of RAM:
     * tilram_min_addr = 13'b0_0000_0000_0000
     * tilram_max_addr = 13'b0_0111_1111_1111
     * patram_min_addr = 13'b0_1000_0000_0000
     * patram_max_addr = 13'b1_0111_1111_1111
     * palram_min_addr = 13'b1_1000_0000_0000
     * palram_max_addr = 13'b1_1001_1111_1111
     * sprram_min_addr = 13'b1_1010_0000_0000
     * sprram_max_addr = 13'b1_1010_0010_0111
     *
     * From this, we can gather the following logic:
     * if bit[12] = 1, then one of patram, palram, or sprram chosen
     *   if also bit [11] = 1, then palram or sprram chosen
     *     if also bit [9] = 1, then sprram is chosen
     *     else, palram is chosen
     *   else patram is chosen
     * else if bit[11], then patram is chosen
     * else, tilram is chosen
     */
    
    // Ensure only 1 signal is set to be active in the following if-else block
    {cpu_choose_patram, cpu_choose_palram, cpu_choose_sprram} = 3'b0;

    // Assign all signals their default values (values when not chosen)
    // TODO: If synthesis complains or FPGA explodes, I need to change this
    cpu_tilram_wraddr  = 'X;
    cpu_tilram_wrdata  = 'X;
    cpu_tilram_byteena = 'X;
    cpu_palram_wraddr  = 'X;
    cpu_palram_wrdata  = 'X;
    cpu_palram_byteena = 'X;
    cpu_patram_wraddr  = 'X;
    cpu_patram_wrdata  = 'X;
    cpu_patram_byteena = 'X;
    cpu_sprram_wraddr  = 'X;
    cpu_sprram_wrdata  = 'X;
    cpu_sprram_byteena = 'X;

    // Since other buses default to don't-cares, wren must be 0 to avoid writing corrupt data.
    cpu_tilram_wren = 1'b0;
    cpu_patram_wren = 1'b0;
    cpu_palram_wren = 1'b0;
    cpu_sprram_wren = 1'b0;

    // Figure out which signal is chosen (Demux select line)
    if (h2f_vram_wraddr[12]) begin
        if (h2f_vram_wraddr[11]) begin
            if (h2f_vram_wraddr[9]) cpu_choose_sprram = 1'b1;
            else cpu_choose_palram = 1'b1;
        end
        else cpu_choose_patram = 1'b1;
    end
    else if (h2f_vram_wraddr[11]) cpu_choose_patram = 1'b1;
    // cpu_choose_tilram = 1'b1 is the default case

    // Demux logic
    // Note, to translate CPU address down to a local RAM address, subtract the start address from
    //   the CPU address
    if (cpu_choose_sprram) begin
        addr_translation   = h2f_vram_wraddr - sprram_start_addr;
        cpu_sprram_wraddr  = addr_translation[5:0];
        cpu_sprram_wren    = h2f_vram_wren;
        cpu_sprram_wrdata  = h2f_vram_wrdata;
        cpu_sprram_byteena = h2f_vram_byteena;
    end
    else if (cpu_choose_palram) begin
        addr_translation   = h2f_vram_wraddr - palram_start_addr;
        cpu_palram_wraddr  = addr_translation[8:0];
        cpu_palram_wren    = h2f_vram_wren;
        cpu_palram_wrdata  = h2f_vram_wrdata;
        cpu_palram_byteena = h2f_vram_byteena;
    end
    else if (cpu_choose_patram) begin
        addr_translation   = h2f_vram_wraddr - patram_start_addr;
        cpu_patram_wraddr  = addr_translation[11:0];
        cpu_patram_wren    = h2f_vram_wren;
        cpu_patram_wrdata  = h2f_vram_wrdata;
        cpu_patram_byteena = h2f_vram_byteena;
    end
    else begin // cpu_choose_tilram
        // Note, no subtraction needs to be done at beginning of VRAM address space.
        addr_translation   = h2f_vram_wraddr;
        cpu_tilram_wraddr  = addr_translation[10:0];
        cpu_tilram_wren    = h2f_vram_wren;
        cpu_tilram_wrdata  = h2f_vram_wrdata;
        cpu_tilram_byteena = h2f_vram_byteena;
    end
end

// === CPU-FACING VRAM ASSIGNMENTS ===
always_comb begin
    // VRAM_C addr_a are always assigned to the vram_sync_writer (which uses it for reads)
    vram_ifC_usr.tilram_addr_a = vram_vsw_ifC_src.tilram_addr_a;
    vram_ifC_usr.patram_addr_a = vram_vsw_ifC_src.patram_addr_a;
    vram_ifC_usr.palram_addr_a = vram_vsw_ifC_src.palram_addr_a;
    vram_ifC_usr.sprram_addr_a = vram_vsw_ifC_src.sprram_addr_a;

    // During sync, VRAM_C addr_b is controlled by vram_sync_writer (for reads). Otherwise, the CPU
    //   uses it for writes.
    vram_ifC_usr.tilram_addr_b = (sync_active) ? vram_vsw_ifC_src.tilram_addr_b : cpu_tilram_wraddr;
    vram_ifC_usr.patram_addr_b = (sync_active) ? vram_vsw_ifC_src.patram_addr_b : cpu_patram_wraddr;
    vram_ifC_usr.palram_addr_b = (sync_active) ? vram_vsw_ifC_src.palram_addr_b : cpu_palram_wraddr;
    vram_ifC_usr.sprram_addr_b = (sync_active) ? vram_vsw_ifC_src.sprram_addr_b : cpu_sprram_wraddr;

    vram_ifC_usr.tilram_byteena_b = (sync_active) ? vram_vsw_ifC_src.tilram_byteena_b : cpu_tilram_byteena;
    vram_ifC_usr.patram_byteena_b = (sync_active) ? vram_vsw_ifC_src.patram_byteena_b : cpu_patram_byteena;
    vram_ifC_usr.palram_byteena_b = (sync_active) ? vram_vsw_ifC_src.palram_byteena_b : cpu_palram_byteena;
    vram_ifC_usr.sprram_byteena_b = (sync_active) ? vram_vsw_ifC_src.sprram_byteena_b : cpu_sprram_byteena;

    // vram_sync_writer does not write to CPU-facing VRAM
    // CPU only uses port b for writes
    vram_ifC_usr.tilram_wrdata_a = 'bX; // must be cautious and ensure wren_a is never high
    vram_ifC_usr.patram_wrdata_a = 'bX;
    vram_ifC_usr.palram_wrdata_a = 'bX;
    vram_ifC_usr.sprram_wrdata_a = 'bX;

    // Again, only CPU writes to CPU-Facing VRAM, and only on port b
    vram_ifC_usr.tilram_wrdata_b = (sync_active) ? 'bX : cpu_tilram_wrdata;
    vram_ifC_usr.patram_wrdata_b = (sync_active) ? 'bX : cpu_patram_wrdata;
    vram_ifC_usr.palram_wrdata_b = (sync_active) ? 'bX : cpu_palram_wrdata;
    vram_ifC_usr.sprram_wrdata_b = (sync_active) ? 'bX : cpu_sprram_wrdata;

    // VRAM_C wren_a should be driven low by vram_sync_writer, since it uses VRAM_C for reads
    vram_ifC_usr.tilram_wren_a = vram_vsw_ifC_src.tilram_wren_a;
    vram_ifC_usr.patram_wren_a = vram_vsw_ifC_src.patram_wren_a;
    vram_ifC_usr.palram_wren_a = vram_vsw_ifC_src.palram_wren_a;
    vram_ifC_usr.sprram_wren_a = vram_vsw_ifC_src.sprram_wren_a;

    // Note, CPU only uses a single port for writes (port b of all VRAM submodules)
    vram_ifC_usr.tilram_wren_b = (sync_active) ? vram_vsw_ifC_src.tilram_wren_a : cpu_tilram_wren;
    vram_ifC_usr.patram_wren_b = (sync_active) ? vram_vsw_ifC_src.patram_wren_a : cpu_patram_wren;
    vram_ifC_usr.palram_wren_b = (sync_active) ? vram_vsw_ifC_src.palram_wren_a : cpu_palram_wren;
    vram_ifC_usr.sprram_wren_b = (sync_active) ? vram_vsw_ifC_src.sprram_wren_a : cpu_sprram_wren;

    // CPU never reads, so assign these to sync_writer (which uses both ports for reads)
    vram_vsw_ifC_src.tilram_rddata_a = vram_ifC_usr.tilram_rddata_a;
    vram_vsw_ifC_src.patram_rddata_a = vram_ifC_usr.patram_rddata_a;
    vram_vsw_ifC_src.palram_rddata_a = vram_ifC_usr.palram_rddata_a;
    vram_vsw_ifC_src.sprram_rddata_a = vram_ifC_usr.sprram_rddata_a;

    vram_vsw_ifC_src.tilram_rddata_b = vram_ifC_usr.tilram_rddata_b;
    vram_vsw_ifC_src.patram_rddata_b = vram_ifC_usr.patram_rddata_b;
    vram_vsw_ifC_src.palram_rddata_b = vram_ifC_usr.palram_rddata_b;
    vram_vsw_ifC_src.sprram_rddata_b = vram_ifC_usr.sprram_rddata_b;
end

// === PPU-FACING VRAM ASSIGNMENTS ===
always_comb begin
    // Sync-writer uses both addresses for writing, PPU-logic uses both addresses for reading
    vram_ifP_usr.tilram_addr_a = (sync_active) ? vram_vsw_ifP_src.tilram_addr_a : vram_ppu_ifP_src.tilram_addr_a;
    vram_ifP_usr.patram_addr_a = (sync_active) ? vram_vsw_ifP_src.patram_addr_a : vram_ppu_ifP_src.patram_addr_a;
    vram_ifP_usr.palram_addr_a = (sync_active) ? vram_vsw_ifP_src.palram_addr_a : vram_ppu_ifP_src.palram_addr_a;
    vram_ifP_usr.sprram_addr_a = (sync_active) ? vram_vsw_ifP_src.sprram_addr_a : vram_ppu_ifP_src.sprram_addr_a;

    vram_ifP_usr.tilram_addr_b = (sync_active) ? vram_vsw_ifP_src.tilram_addr_b : vram_ppu_ifP_src.tilram_addr_b;
    vram_ifP_usr.patram_addr_b = (sync_active) ? vram_vsw_ifP_src.patram_addr_b : vram_ppu_ifP_src.patram_addr_b;
    vram_ifP_usr.palram_addr_b = (sync_active) ? vram_vsw_ifP_src.palram_addr_b : vram_ppu_ifP_src.palram_addr_b;
    vram_ifP_usr.sprram_addr_b = (sync_active) ? vram_vsw_ifP_src.sprram_addr_b : vram_ppu_ifP_src.sprram_addr_b;

    // PPU doesn't write to PPU-Facing, only sync-writer does
    vram_ifP_usr.tilram_byteena_b = (sync_active) ? vram_vsw_ifP_src.tilram_byteena_b : vram_ppu_ifP_src.tilram_byteena_b;
    vram_ifP_usr.patram_byteena_b = (sync_active) ? vram_vsw_ifP_src.patram_byteena_b : vram_ppu_ifP_src.patram_byteena_b;
    vram_ifP_usr.palram_byteena_b = (sync_active) ? vram_vsw_ifP_src.palram_byteena_b : vram_ppu_ifP_src.palram_byteena_b;
    vram_ifP_usr.sprram_byteena_b = (sync_active) ? vram_vsw_ifP_src.sprram_byteena_b : vram_ppu_ifP_src.sprram_byteena_b;

    // Again, PPU doesn't write to PPU-Facing, only sync-writer does
    vram_ifP_usr.tilram_wrdata_a = vram_vsw_ifP_src.tilram_wrdata_a;
    vram_ifP_usr.patram_wrdata_a = vram_vsw_ifP_src.patram_wrdata_a;
    vram_ifP_usr.palram_wrdata_a = vram_vsw_ifP_src.palram_wrdata_a;
    vram_ifP_usr.sprram_wrdata_a = vram_vsw_ifP_src.sprram_wrdata_a;

    vram_ifP_usr.tilram_wrdata_b = vram_vsw_ifP_src.tilram_wrdata_b;
    vram_ifP_usr.patram_wrdata_b = vram_vsw_ifP_src.patram_wrdata_b;
    vram_ifP_usr.palram_wrdata_b = vram_vsw_ifP_src.palram_wrdata_b;
    vram_ifP_usr.sprram_wrdata_b = vram_vsw_ifP_src.sprram_wrdata_b;

    // Sync writer writes to PPU-Facing, and PPU reads from PPU-Facing
    vram_ifP_usr.tilram_wren_a = (sync_active) ? vram_vsw_ifP_src.tilram_wren_a : vram_ppu_ifP_src.tilram_wren_a;
    vram_ifP_usr.patram_wren_a = (sync_active) ? vram_vsw_ifP_src.patram_wren_a : vram_ppu_ifP_src.patram_wren_a;
    vram_ifP_usr.palram_wren_a = (sync_active) ? vram_vsw_ifP_src.palram_wren_a : vram_ppu_ifP_src.palram_wren_a;
    vram_ifP_usr.sprram_wren_a = (sync_active) ? vram_vsw_ifP_src.sprram_wren_a : vram_ppu_ifP_src.sprram_wren_a;

    vram_ifP_usr.tilram_wren_b = (sync_active) ? vram_vsw_ifP_src.tilram_wren_b : vram_ppu_ifP_src.tilram_wren_b;
    vram_ifP_usr.patram_wren_b = (sync_active) ? vram_vsw_ifP_src.patram_wren_b : vram_ppu_ifP_src.patram_wren_b;
    vram_ifP_usr.palram_wren_b = (sync_active) ? vram_vsw_ifP_src.palram_wren_b : vram_ppu_ifP_src.palram_wren_b;
    vram_ifP_usr.sprram_wren_b = (sync_active) ? vram_vsw_ifP_src.sprram_wren_b : vram_ppu_ifP_src.sprram_wren_b;

    // Only PPU-logic reads from PPU-Facing
    vram_ppu_ifP_src.tilram_rddata_a = vram_ifP_usr.tilram_rddata_a;
    vram_ppu_ifP_src.patram_rddata_a = vram_ifP_usr.patram_rddata_a;
    vram_ppu_ifP_src.palram_rddata_a = vram_ifP_usr.palram_rddata_a;
    vram_ppu_ifP_src.sprram_rddata_a = vram_ifP_usr.sprram_rddata_a;

    vram_ppu_ifP_src.tilram_rddata_b = vram_ifP_usr.tilram_rddata_b;
    vram_ppu_ifP_src.patram_rddata_b = vram_ifP_usr.patram_rddata_b;
    vram_ppu_ifP_src.palram_rddata_b = vram_ifP_usr.palram_rddata_b;
    vram_ppu_ifP_src.sprram_rddata_b = vram_ifP_usr.sprram_rddata_b;
end

endmodule : vram_interconnect