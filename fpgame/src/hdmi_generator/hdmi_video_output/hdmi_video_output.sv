module hdmi_video_output (
    input logic video_clk,
    input logic rst_n,

    // to HDMI output
    output logic vga_pclk,
    output logic vga_de,
    output logic vga_hs,
    output logic vga_vs,
    output logic [23:0] vga_rgb,

    // to PPU
    input  logic [9:0]  rowram_rddata,
    output logic [8:0]  rowram_rdaddr,
    input  logic [63:0] palram_rddata,
    output logic [8:0]  palram_rdaddr,
    output logic        rowram_swap
);

    // Base timings obtained from: http://tinyvga.com/vga-timing/640x480@60Hz
    // === Base timings (horizontal) ===
    parameter [9:0] h_visible = 640;
    parameter [9:0] h_frontporch = 16;
    parameter [9:0] h_sync = 96;
    parameter [9:0] h_backporch = 48;
    parameter [9:0] h_total = 800;
    /* For 640x480:
     * h_sync is active       [0, 95]
     * h_backporch is active  [96, 143]
     * h_de is active         [144, 783]
     * h_frontporch is active [784, 799]
    */

    // === Base timings (vertical) ===
    parameter [9:0] v_visible = 10'd480;
    parameter [9:0] v_frontporch = 10'd10;
    parameter [9:0] v_sync = 10'd2;
    parameter [9:0] v_backporch = 10'd33;
    parameter [9:0] v_total = 10'd525;
    /* For 640x480:
     * v_sync is active       [0, 1]
     * v_backporch is active  [2, 34]
     * v_de is active         [35, 514]
     * v_frontporch is active [515, 524]
    */

    //=======================================================
    // Signals
    //=======================================================
    logic [9:0] h_count;   // horizontal/column count
    logic [9:0] v_count;   // vertical/row count
    logic h_de, v_de;     // horizontal and vertical display-enable signals
    logic addr_toggle = 1'b0; // use to keep track of when to change row-buffer addresses
    logic [8:0] n_rowram_rdaddr; // next row-ram read address
    logic n_addr_toggle;
    logic [23:0] n_vga_rgb;
    logic palram_datasel; // store LSB of rowram_rddata to translate from 32-bit to 64-bit rd addr

    enum { IDLE, SWAP, DISPLAY } c_state, n_state;
     

    //=======================================================
    // Combinational Logic
    //=======================================================
    assign vga_pclk = video_clk;

    assign h_de = (h_count >= h_sync + h_backporch) &&
                  (h_count < h_sync + h_backporch + h_visible);
    assign v_de = (v_count >= v_sync + v_backporch) &&
                  (v_count < v_sync + v_backporch + v_visible);
    assign vga_de = h_de & v_de;

    assign vga_hs = ~(h_count < h_sync);
    assign vga_vs = ~(v_count < v_sync);

    // === Next-State Logic ===
    always_comb begin
        rowram_swap = 1'b0;
        n_rowram_rdaddr = rowram_rdaddr;
        n_addr_toggle = 1'b0;
        n_vga_rgb = 24'h000000; // Regular Analog video requires black color during blank
		  
        unique case (c_state)
            IDLE: begin
                n_state = (h_count == h_sync + h_backporch - 6) ? SWAP : IDLE;
            end
            SWAP: begin
                rowram_swap = 1'b1;
                n_rowram_rdaddr = 9'b0; // Reset the pixel address before we enter DISPLAY
                n_state = DISPLAY;
            end
            DISPLAY: begin
                if (addr_toggle == 1 && h_count < h_sync + h_backporch + h_visible - 5)
                    n_rowram_rdaddr = rowram_rdaddr + 9'b1; // Increment pixel address every 2 px

                n_addr_toggle = ~addr_toggle;
                n_vga_rgb = (palram_datasel) ? palram_rddata[55:32] : palram_rddata[23:0];

                // As soon as we are about to enter the horizontal front porch, transition to IDLE
                n_state = (h_count == h_sync + h_backporch + h_visible - 1) ? IDLE : DISPLAY;
            end
        endcase
    end

    //=======================================================
    // Sequential Logic
    //=======================================================

    // === FSM ===
    always_ff @(posedge video_clk or negedge rst_n) begin
        if (!rst_n) begin
            rowram_rdaddr <= 9'b0;
            palram_rdaddr <= 9'b0;
            palram_datasel <= 0;
            addr_toggle <= 1'b0;
            c_state <= IDLE;
            vga_rgb <= 24'b0;
        end
        else begin
            rowram_rdaddr <= n_rowram_rdaddr;
            palram_rdaddr <= rowram_rddata[9:1];
            palram_datasel <= rowram_rddata[0];
            addr_toggle <= n_addr_toggle;
            vga_rgb <= n_vga_rgb;

            c_state <= n_state;
        end
    end

    // === Horizontal control signals ===
    always_ff @(posedge video_clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 10'b0;
        end
        else begin
            // reset the horizontal counter after it reaches the h_total pixel
            if (h_count == h_total - 1)
                h_count <= 10'b0;
            else
                h_count <= h_count + 10'b1;
        end
    end

    // === Vertical control signals ===
    always_ff @(posedge video_clk or negedge rst_n) begin
        if(!rst_n) begin
            v_count <= 10'b0;
        end
        else if (h_count == h_total - 1) begin
            if (v_count == v_total - 1)
                v_count <= 10'b0;
            else
                v_count <= v_count + 10'b1;
        end
    end

endmodule : hdmi_video_output
