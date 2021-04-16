/* ppu.sv
 * Implements the Pixel Processing Unit.
 */
/* Overview
 * This module is the top level module for the PPU. It has several jobs:
 * 1. We instantiate and connect the various PPU Structures, such as:
 *    * ppu_logic: HDMI video output reads this module, which returns video data based on vram and
 *                 dbuf_ppu_ctrl_regs.
 *
 *    * vram:      Video RAM. Split into 2 VRAM copies - one PPU-Facing (accessible by the PPU) and
 *                 one CPU-Facing (accessible by DMA from CPU). These sections are sychronized by
 *                 vram_sync_writer after a successful DMA from CPU memory into the CPU-Facing VRAM.
 *                 Each VRAM is split into 4 sections which tell ppu_logic what to display for
 *                 different data types (tiles, sprites, patterns, and palettes).
 *
 *    * vram_sync_writer: Copies from CPU-Facing VRAM to PPU-Facing VRAM, synchronizing them.
 *
 *    * vram_interconnect: Both ppu_logic, the DMA-Engine, and vram_sync_writer use vram, so we need
 *                         a more complex interconnect structure to manage these connections.
 *
 *    * dbuf_ppu_ctrl_regs: Ensures PPU-Facing Control registers are synced with the CPU-Facing
 *                          Control registers whenever VRAM sync occurs.
 *
 * 2. We implement the PPU FSM, which determines the communication protocol with the CPU. This
 *    involves:
 *    * ppu_dma_rdy_irq: A CPU interrupt which is asserted by the PPU when the PPU is ready to
 *                       receive another DMA transfer.
 *
 *    * vramsrcaddrpio:  A register that the CPU can write an address to in order to signal to the
 *                       PPU that a DMA transfer should start. The register itself gives a "avail"
 *                       signal whenever a new DMA address is available.
 */

module ppu (
    input logic clk,
    input logic rst_n,

    // from/to HDMI video output
    output logic [9:0]   hdmi_rowram_rddata,
    input  logic [8:0]   hdmi_rowram_rdaddr,
    output logic [23:0]  hdmi_color_rddata,
    input  logic [9:0]   hdmi_color_rdaddr,
    input  logic         rowram_swap,
    input  logic [7:0]   next_row,
    input  logic         vblank_start,
    input  logic         vblank_end_soon,

    // h2f_vram_avalon_interface (essentially the CPU->VRAM write interface)
    input  logic [11:0]  h2f_vram_wraddr,
    input  logic         h2f_vram_wren,
    input  logic [127:0] h2f_vram_wrdata,

    // Double-buffer these pio inputs. Change when we do SYNC
    input  logic [31:0]  ppu_bgscroll,
    input  logic [31:0]  ppu_fgscroll,
    input  logic [2:0]   ppu_enable,
    input  logic [23:0]  ppu_bgcolor,
    
    // DMA Source Address PIO
    input  logic [31:0]  vramsrcaddrpio_rddata,
    input  logic         vramsrcaddrpio_update_avail,
    output logic         vramsrcaddrpio_read_rst,

    // DMA-Engine connections
    output logic [31:0]  dma_engine_src_addr,
    output logic         dma_engine_start,
    input  logic         dma_engine_finish,

    output logic         ppu_dma_rdy_irq
);

    // Routing for the following interfaces is handled by vram_interconnect.
    // These interfaces will connect to vram_ifP and vram_ifC depending on the PPU state.

    // Actual PPU-Facing VRAM interface. Both ports are either exposed to the vram_sync_writer or
    //   the ppu_logic, depending on PPU state.
    vram_if_ppu_facing vram_ifP();

    // Actual CPU-Facing VRAM interface. Half is connected to the vram_sync_writer, half is exposed
    //   to the dma_engine.
    vram_if_cpu_facing vram_ifC();

    // VRAM interface used by vram_sync_writer. Routed to vram_ifP in sync_active
    vram_if_ppu_facing vram_vsw_ifP();

    // VRAM interface used by ppu_logic. Routed to vram_ifP in !sync_active.
    vram_if_ppu_facing vram_ppu_ifP();

    // VRAM interface used by vram_sync_writer. Connected only to a single port of vram_ifC.
    vram_if_cpu_facing vram_vsw_ifC();

    logic vram_sync, n_vram_sync;
    //logic vram_sync_sent, n_vram_sync_sent;
    logic vram_sync_done;
    logic sync_active;
    logic rowram_swap_disp;
    logic dma_rdy_for_sync, n_dma_rdy_for_sync;
    logic [31:0] n_dma_engine_src_addr;
    logic n_dma_engine_start;
    logic n_ppu_dma_rdy_irq;

    logic [31:0] bgscroll;
    logic [31:0] fgscroll;
    logic [2:0]  enable;
    logic [23:0] bgcolor;

    enum { 
        PPU_IDLE, // DMA either took too long, no DMA transfer even started, or we are just starting
        PPU_DISP, // ppu_logic reads the PPU-Facing VRAM, DMA is likely in progress or complete
        PPU_SYNC  // Syncing changes made by a complete DMA transfer to the PPU-Facing VRAM
    } state, n_state;


    // ===============================
    // === Submodule Instantiation ===
    // ===============================
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
        .done(vram_sync_done),
        .vram_ifP_usr(vram_vsw_ifP.usr),
        .vram_ifC_usr(vram_vsw_ifC.usr)
    );

    ppu_logic ppul (
        .clk,
        .rst_n,
        .hdmi_rowram_rddata,
        .hdmi_rowram_rdaddr,
        .hdmi_color_rddata,
        .hdmi_color_rdaddr,
        .rowram_swap(rowram_swap_disp),
        .next_row,
        .vram_ppu_ifP_usr(vram_ppu_ifP.usr),
        .bgscroll,
        .fgscroll,
        .enable,
        .bgcolor
    );

    // Decides who gets the access to the PPU-Facing and CPU-Facing VRAMs
    vram_interconnect vi (
        .h2f_vram_wraddr,
        .h2f_vram_wren,
        .h2f_vram_wrdata,
        .sync_active(sync_active),
        .vram_ifP_usr(vram_ifP.usr),
        .vram_ifC_usr(vram_ifC.usr),
        .vram_vsw_ifP_src(vram_vsw_ifP.src),
        .vram_vsw_ifC_src(vram_vsw_ifC.src),
        .vram_ppu_ifP_src(vram_ppu_ifP.src)
    );

    // Buffered control registers synced along with the PPU-Facing VRAM.
    dbuf_ppu_ctrl_regs dpcr (
        .clk,
        .rst_n,
        .sync(vram_sync), // Control regs sync along with the VRAMs
        .ppu_bgscroll,
        .ppu_fgscroll,
        .ppu_enable,
        .ppu_bgcolor,
        .dbuf_bgscroll(bgscroll),
        .dbuf_fgscroll(fgscroll),
        .dbuf_enable(enable),
        .dbuf_bgcolor(bgcolor)
    );

    // ===============
    // === PPU FSM ===
    // ===============
    // row-ram swap signal is ignored at all non-display times
    assign rowram_swap_disp = (state == PPU_DISP && rowram_swap);
    // During sync, vram_interconnect automatically assigns VRAM's signals to the vram_sync_writer.
    assign sync_active = (state == PPU_SYNC);

    // === next-state logic ===
    always_comb begin
        // default next-signal states
        n_vram_sync = 1'b0;
        n_dma_rdy_for_sync = dma_rdy_for_sync;
        n_dma_engine_src_addr = dma_engine_src_addr;
        n_dma_engine_start = 1'b0;
        vramsrcaddrpio_read_rst = 1'b0;
        n_ppu_dma_rdy_irq = 1'b0;

        unique case (state)
            PPU_IDLE: begin
                // If we do not yet have a DMA transfer completed (ready to be synced), or we are
                //   just starting), then we simply wait for the PPU_DISP period to begin.
                // This will repeat the last buffered frame in PPU-Facing VRAM, without syncing.

                if (vblank_end_soon) n_state = PPU_DISP;
                else n_state = PPU_IDLE;
            end
            PPU_DISP: begin
                // If we have a DMA finished (ready to be synced), then go to sync, else, go to IDLE
                //   and do nothing.
                if (vblank_start) begin
                    if (dma_rdy_for_sync) begin
                        n_state = PPU_SYNC;
                        n_vram_sync = 1'b1;
                    end
                    else n_state = PPU_IDLE;
                end
                else n_state = PPU_DISP;
            end
            PPU_SYNC: begin
                // Once we are done syncing the last DMA, we can tell the CPU to DMA the next VRAM
                //   data whenever it is ready to do so.
                if (vram_sync_done) begin
                    n_dma_rdy_for_sync = 1'b0;
                    n_ppu_dma_rdy_irq = 1'b1;

                    // Note, THIS IS GUARANTEED TO OCCUR IN PPU_SYNC. However, logic synthesis should be
                    //   simpler if "could" occur at any time.
                end

                if (vblank_end_soon) begin
                    n_state = PPU_DISP;
                end
                else n_state = PPU_SYNC;
            end
        endcase

        // === Conditions that can occur in any of the three states ===
        // technically, the dma_engine_finish can only occur after a dma_engine_start, which can
        //   occur only outside of the actual syncwriter sync period.
        if (dma_engine_finish) begin
            n_dma_rdy_for_sync = 1'b1;
        end

        if (vramsrcaddrpio_update_avail && !dma_rdy_for_sync) begin
            // read in the new DMA source address and start the DMA on the next clock edge
            n_dma_engine_src_addr = vramsrcaddrpio_rddata;
            n_dma_engine_start = 1'b1;

            // We are reading on the next clock edge, so tell pio to clear the "update available"
            //   signal.
            vramsrcaddrpio_read_rst = 1'b1;

            // Also note that this IF will be true only once per interrupt, since there should be no
            //   CPU writes (and thus no update_avail) until the DMA has finished, the changes have
            //   been synced, and ppu_dma_rdy_irq has been sent out.
        end
    end

    // === Transition Logic ===
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            // Start FSM in IDLE. We will always lose the first frame, but we will be able to
            //   account for the case where 
            state <= PPU_IDLE;

            vram_sync      <= 1'b0;

            dma_rdy_for_sync    <= 1'b0;
            dma_engine_src_addr <= 32'd0;
            dma_engine_start    <= 1'b0;

            ppu_dma_rdy_irq <= 1'b0;
        end
        else begin
            state <= n_state;

            vram_sync      <= n_vram_sync;

            dma_rdy_for_sync    <= n_dma_rdy_for_sync;
            dma_engine_src_addr <= n_dma_engine_src_addr;
            dma_engine_start    <= n_dma_engine_start;

            ppu_dma_rdy_irq <= n_ppu_dma_rdy_irq;
        end
    end

endmodule : ppu