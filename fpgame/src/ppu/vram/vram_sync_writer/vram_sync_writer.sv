/* vram_sync_writer.sv
 * Upon receiving the sync signal, begins the transfer of the entire CPU-Facing VRAM to the
 *   PPU-Facing VRAM.
 */
/* Sync-Writer Organization
 * To accomplish data transfer, we utilize the sync_writer modules on one or more VRAM ports.
 * Each of the four CPU-Facing VRAM segments has a 128-bit read port. For each of the four segments,
 *   We read from the 128-bit port, and proceed to write each 64-bit slice of that 128-bit read data
 *   into one of 2 64-bit ports on the PPU-Facing VRAM.
 * This requires one sync-writer per segment, but the write-data output must be split, and the
 *   write-address must be split into current-address, current-address + 1, and incremented by 2
 *   (instead of the usual 1) on each consecutive write.
 */

module vram_sync_writer (
    input  logic clk,
    input  logic rst_n,
    input  logic sync,
    output logic done,

    // vram output interfaces
    vram_if_ppu_facing.usr vram_ifP_usr,
    vram_if_cpu_facing.usr vram_ifC_usr
);

// We always sync from VRAM-C (CPU FACING) to VRAM-P (PPU-FACING).

// Since this module never writes to vram_ifC or uses its port b in any way, leave those ports as
//   "don't-cares" or defaults.
assign vram_ifC_usr.tilram_wrdata_a = 'X;
assign vram_ifC_usr.patram_wrdata_a = 'X;
assign vram_ifC_usr.palram_wrdata_a = 'X;
assign vram_ifC_usr.sprram_wrdata_a = 'X;

assign vram_ifC_usr.tilram_wrdata_b = 'X;
assign vram_ifC_usr.patram_wrdata_b = 'X;
assign vram_ifC_usr.palram_wrdata_b = 'X;
assign vram_ifC_usr.sprram_wrdata_b = 'X;

assign vram_ifC_usr.tilram_addr_b = '0;
assign vram_ifC_usr.patram_addr_b = '0;
assign vram_ifC_usr.palram_addr_b = '0;
assign vram_ifC_usr.sprram_addr_b = '0;

assign vram_ifC_usr.tilram_wren_b = 1'b0;
assign vram_ifC_usr.patram_wren_b = 1'b0;
assign vram_ifC_usr.palram_wren_b = 1'b0;
assign vram_ifC_usr.sprram_wren_b = 1'b0;

enum { IDLE, SYNC } state;

// registers representing "done signal seen"
logic tilram_sync_done, patram_sync_done, palram_sync_done, sprram_sync_done;

// done signal wires
logic tilram_sync_done_sig, patram_sync_done_sig, palram_sync_done_sig, sprram_sync_done_sig;


// =============================
// === Tile-RAM Synchronizer ===
// =============================
// Tile RAM synchronizer copies the CPU-Facing Tile RAM to PPU-Facing Tile RAM
logic [9:0]   tilram_sync_addrP;
logic [127:0] tilram_sync_wrdataP;
logic         tilram_sync_wren;
sync_writer #(
    .DATA_WIDTH(128),
    .ADDR_WIDTH(10),
    .MAX_ADDR(1023)
) tilram_sync (
    .clk,
    .rst_n,
    .sync,
    .done(        tilram_sync_done_sig),
    .clr_done(    1'b0),
    .addr_from(   vram_ifC_usr.tilram_addr_a),
    .wren_from(   vram_ifC_usr.tilram_wren_a),
    .rddata_from( vram_ifC_usr.tilram_rddata_a),
    .addr_to(     tilram_sync_addrP),
    .byteena_to(),
    .wrdata_to(   tilram_sync_wrdataP),
    .wren_to(     tilram_sync_wren)
);

// The PPU-Facing VRAM (64-bit) has its data, address, and wren split from a single sync-writer,
//   which reads from the 128-bit CPU-Facing VRAM.
// Port A gets the first 64-bits
assign vram_ifP_usr.tilram_addr_a   = {tilram_sync_addrP, 1'b0};
assign vram_ifP_usr.tilram_wrdata_a =  tilram_sync_wrdataP[63:0];
assign vram_ifP_usr.tilram_wren_a   =  tilram_sync_wren;

// Port B gets the second 64-bits
assign vram_ifP_usr.tilram_addr_b   = {tilram_sync_addrP, 1'b1};
assign vram_ifP_usr.tilram_wrdata_b =  tilram_sync_wrdataP[127:64];
assign vram_ifP_usr.tilram_wren_b   =  tilram_sync_wren;


// ================================
// === Pattern-RAM Synchronizer ===
// ================================
// Pattern-RAM synchronizer copies the CPU-Facing Pattern-RAM to PPU-Facing Pattern-RAM
logic [10:0]  patram_sync_addrP;
logic [127:0] patram_sync_wrdataP;
logic         patram_sync_wren;
sync_writer #(
    .DATA_WIDTH(128),
    .ADDR_WIDTH(11),
    .MAX_ADDR(2047)
) patram_sync (
    .clk,
    .rst_n,
    .sync,
    .done(        patram_sync_done_sig),
    .clr_done(    1'b0),
    .addr_from(   vram_ifC_usr.patram_addr_a),
    .wren_from(   vram_ifC_usr.patram_wren_a),
    .rddata_from( vram_ifC_usr.patram_rddata_a),
    .addr_to(     patram_sync_addrP),
    .byteena_to(),
    .wrdata_to(   patram_sync_wrdataP),
    .wren_to(     patram_sync_wren)
);

// The PPU-Facing VRAM (64-bit) has its data, address, and wren split from a single sync-writer,
//   which reads from the 128-bit CPU-Facing VRAM.
// Port A gets the first 64-bits
assign vram_ifP_usr.patram_addr_a   = {patram_sync_addrP, 1'b0};
assign vram_ifP_usr.patram_wrdata_a =  patram_sync_wrdataP[63:0];
assign vram_ifP_usr.patram_wren_a   =  patram_sync_wren;

// Port B gets the second 64-bits
assign vram_ifP_usr.patram_addr_b   = {patram_sync_addrP, 1'b1};
assign vram_ifP_usr.patram_wrdata_b =  patram_sync_wrdataP[127:64];
assign vram_ifP_usr.patram_wren_b   =  patram_sync_wren;


// ================================
// === Palette-RAM Synchronizer ===
// ================================
// Palette-RAM synchronizer copies the CPU-Facing Palette-RAM to PPU-Facing Palette-RAM
logic [7:0]   palram_sync_addrP;
logic [127:0] palram_sync_wrdataP;
logic         palram_sync_wren;
sync_writer #(
    .DATA_WIDTH(128),
    .ADDR_WIDTH(8),
    .MAX_ADDR(255)
) palram_sync (
    .clk,
    .rst_n,
    .sync,
    .done(        palram_sync_done_sig),
    .clr_done(    1'b0),
    .addr_from(   vram_ifC_usr.palram_addr_a),
    .wren_from(   vram_ifC_usr.palram_wren_a),
    .rddata_from( vram_ifC_usr.palram_rddata_a),
    .addr_to(     palram_sync_addrP),
    .byteena_to(),
    .wrdata_to(   palram_sync_wrdataP),
    .wren_to(     palram_sync_wren)
);

// The PPU-Facing VRAM (64-bit) has its data, address, and wren split from a single sync-writer,
//   which reads from the 128-bit CPU-Facing VRAM.
// Port A gets the first 64-bits
assign vram_ifP_usr.palram_addr_a   = {palram_sync_addrP, 1'b0};
assign vram_ifP_usr.palram_wrdata_a =  palram_sync_wrdataP[63:0];
assign vram_ifP_usr.palram_wren_a   =  palram_sync_wren;

// Port B gets the second 64-bits
assign vram_ifP_usr.palram_addr_b   = {palram_sync_addrP, 1'b1};
assign vram_ifP_usr.palram_wrdata_b =  palram_sync_wrdataP[127:64];
assign vram_ifP_usr.palram_wren_b   =  palram_sync_wren;


// ===============================
// === Sprite-RAM Synchronizer ===
// ===============================
// Sprite-RAM synchronizer copies the CPU-Facing Sprite-RAM to PPU-Facing Sprite-RAM
logic [4:0]   sprram_sync_addrP;
logic [127:0] sprram_sync_wrdataP;
logic         sprram_sync_wren;
sync_writer #(
    .DATA_WIDTH(128),
    .ADDR_WIDTH(5),
    .MAX_ADDR(19)
) sprram_sync (
    .clk,
    .rst_n,
    .sync,
    .done(        sprram_sync_done_sig),
    .clr_done(    1'b0),
    .addr_from(   vram_ifC_usr.sprram_addr_a),
    .wren_from(   vram_ifC_usr.sprram_wren_a),
    .rddata_from( vram_ifC_usr.sprram_rddata_a),
    .addr_to(     sprram_sync_addrP),
    .byteena_to(),
    .wrdata_to(   sprram_sync_wrdataP),
    .wren_to(     sprram_sync_wren)
);

// The PPU-Facing VRAM (64-bit) has its data, address, and wren split from a single sync-writer,
//   which reads from the 128-bit CPU-Facing VRAM.
// Port A gets the first 64-bits
assign vram_ifP_usr.sprram_addr_a   = {sprram_sync_addrP, 1'b0};
assign vram_ifP_usr.sprram_wrdata_a =  sprram_sync_wrdataP[63:0];
assign vram_ifP_usr.sprram_wren_a   =  sprram_sync_wren;

// Port B gets the second 64-bits
assign vram_ifP_usr.sprram_addr_b   = {sprram_sync_addrP, 1'b1};
assign vram_ifP_usr.sprram_wrdata_b =  sprram_sync_wrdataP[127:64];
assign vram_ifP_usr.sprram_wren_b   =  sprram_sync_wren;


// ===========
// === FSM ===
// ===========
assign done = (tilram_sync_done & patram_sync_done & palram_sync_done & sprram_sync_done);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        //reset state and control signals
        state <= IDLE;
        {tilram_sync_done, patram_sync_done, palram_sync_done, sprram_sync_done} <= 4'b0;
    end
    else begin
        unique case (state)
            IDLE: begin
                if (sync) begin
                    state <= SYNC;
                end
            end
            SYNC: begin
                // monitor each done signal and store the ones we have seen
                if (tilram_sync_done_sig) tilram_sync_done <= 1'b1;
                if (patram_sync_done_sig) patram_sync_done <= 1'b1;
                if (palram_sync_done_sig) palram_sync_done <= 1'b1;
                if (sprram_sync_done_sig) sprram_sync_done <= 1'b1;

                // if all writes are done, exit to idle and assert sync signal
                if (done) begin
                    state <= IDLE;
                    // reset done state:
                    {tilram_sync_done, patram_sync_done, palram_sync_done, sprram_sync_done} <= 4'b0;
                end
            end
        endcase
    end
end

endmodule : vram_sync_writer