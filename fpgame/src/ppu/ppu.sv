/* ppu.sv
 * Implements the Pixel Processing Unit.
 * TODO: Come on Joe, this needs more documentation.
 */

module ppu (
    input logic clk,
    input logic rst_n,

    // from/to HDMI video output
    output logic [9:0]  hdmi_rowram_rddata,
    input  logic [8:0]  hdmi_rowram_rdaddr,
    output logic [63:0] hdmi_palram_rddata,
    input  logic [8:0]  hdmi_palram_rdaddr,
    input  logic        rowram_swap,
    input  logic        vblank_start,
    input  logic        vblank_end_soon,

    // h2f_vram_avalon_interface (essentially the CPU->VRAM write interface)
    input  logic [12:0] h2f_vram_wraddr,
    input  logic        h2f_vram_wren,
    input  logic [63:0] h2f_vram_wrdata,
    input  logic [7:0]  h2f_vram_byteena,
    output logic        cpu_vram_wr_irq,
    input  logic        cpu_wr_busy
);

    vram_if vram_ifP(); // Actual PPU-Facing VRAM interface
    vram_if vram_ifC(); // Actual CPU-Facing VRAM interface
    // Routing for the following interfaces is handled by vram_interconnect.
    vram_if vram_vsw_ifP(); // VRAM interface used by vram_sync_writer. Routed to vram_ifP in sync
    vram_if vram_vsw_ifC(); // VRAM interface used by vram_sync_writer. Routed to vram_ifC in sync
    vram_if vram_ppu_ifP(); // VRAM interface used by ppu_logic. Routed to vram_ifP during !sync.
    // These interfaces will connect to vram_ifP and vram_ifC depending on the PPU state.

    logic vram_sync, n_vram_sync, vram_sync_sent, n_vram_sync_sent;
    logic n_cpu_vram_wr_irq;
    logic sync_active;
    logic rowram_swap_disp;
    
    enum { 
        PPU_SYNC, // Either syncing VRAMs or initial state (waiting for first PPU_DISP)
        //PPU_IRQ,  // One extra state to delay the cpu_vram_wr_irq by one cycle
        PPU_DISP, // ppu_logic reads the PPU-Facing VRAM and cpu_logic writes the CPU-Facing VRAM
        PPU_LATE  // CPU failed to complete its writes in time. No syncing or CPU IRQ occurs
    } state, n_state;

    // === Module Instantiation ===
    vram vr (
        .clk,
        .rst_n,
        .vram_ifP_src(vram_ifP.src), // PPU-Logic-Facing VRAM
        .vram_ifC_src(vram_ifC.src)  // CPU-Facing VRAM
    );

    vram_sync_writer vsw (
        .clk,
        .rst_n,
        .sync(vram_sync),
        .done(),
        .vram_ifP_usr(vram_vsw_ifP.usr),
        .vram_ifC_usr(vram_vsw_ifC.usr)
    );

    ppu_logic ppul (
        .clk,
        .rst_n,
        .hdmi_rowram_rddata,
        .hdmi_rowram_rdaddr,
        .hdmi_palram_rddata,
        .hdmi_palram_rdaddr,
        .rowram_swap(rowram_swap_disp),
        .vram_ppu_ifP_usr(vram_ppu_ifP.usr)
    );

    // Decides who gets the access to the PPU-Facing and CPU-Facing VRAMs
    vram_interconnect vi (
        .h2f_vram_wraddr,
        .h2f_vram_wren,
        .h2f_vram_wrdata,
        .h2f_vram_byteena,
        .sync_active(sync_active),
        .vram_ifP_usr(vram_ifP.usr),
        .vram_ifC_usr(vram_ifC.usr),
        .vram_vsw_ifP_src(vram_vsw_ifP.src),
        .vram_vsw_ifC_src(vram_vsw_ifC.src),
        .vram_ppu_ifP_src(vram_ppu_ifP.src)
    );

    // === PPU FSM ===
    // next-state logic
    always_comb begin
        // default next-signal states
        n_cpu_vram_wr_irq = 1'b0;
        n_vram_sync = 1'b0;
        n_vram_sync_sent = vram_sync_sent;
        sync_active = 1'b0;
        rowram_swap_disp = 1'b0;

        unique case (state)
            PPU_SYNC: begin
                // During sync, the vram_interconnect automatically assigns the vram's signals to
                //   the vram_sync_writer.
                sync_active = 1'b1;

                n_vram_sync = !vram_sync_sent; // Only send the sync signal once per SYNC state
                n_vram_sync_sent = 1'b1;
                // There is a short delay to ease timing requirements on sync_active switching the
                //   interconnect. TODO: Maybe this extra cycle of timing slack isn't needed

                if (vblank_end_soon) begin
                    n_state = PPU_DISP;
                    
                    n_vram_sync_sent = 1'b0; // reset the sync-sent flag for later reuse
                    n_cpu_vram_wr_irq = 1'b1; // tell the CPU it is okay to write
                end
                else n_state = PPU_SYNC;
            end
            PPU_DISP: begin
                // row-ram swap signal is ignored at all non-display times
                rowram_swap_disp = rowram_swap; // only accept the signal in display

                if (vblank_start) n_state = (cpu_wr_busy) ? PPU_LATE : PPU_SYNC;
                else n_state = PPU_DISP;
            end
            PPU_LATE: begin
                // If PPU is late, do no syncing. Let the CPU finish its writes.
                // We can only escape the LATE state if the CPU has finished its writes
                if (vblank_end_soon) n_state = (cpu_wr_busy) ? PPU_LATE : PPU_DISP;
                else n_state = PPU_LATE;
            end
        endcase
    end

    // transition logic
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state <= PPU_SYNC;
            cpu_vram_wr_irq <= 1'b0;
            vram_sync_sent <= 1'b0;
        end
        else begin
            state <= n_state;
            cpu_vram_wr_irq <= n_cpu_vram_wr_irq;
            vram_sync <= n_vram_sync;
            vram_sync_sent <= n_vram_sync_sent;
        end
    end

endmodule : ppu