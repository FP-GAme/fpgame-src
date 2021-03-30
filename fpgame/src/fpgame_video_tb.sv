`timescale 1ns/1ns

module fpgame_video_tb;
    // Inputs / Controls
    logic clk, video_clk;
    logic rst_n;
    logic [12:0] h2f_vram_wraddr;
    logic        h2f_vram_wren;
    logic [63:0] h2f_vram_wrdata;
    logic [7:0]  h2f_vram_byteena;

    // Outputs / Interconnect
    logic [9:0]  hdmi_rowram_rddata;
    logic [8:0]  hdmi_rowram_rdaddr;
    logic [63:0] hdmi_palram_rddata;
    logic [8:0]  hdmi_palram_rdaddr;
    logic        rowram_swap;
    logic        vblank_start;
    logic        vblank_end_soon;
    logic        cpu_vram_wr_irq;
    logic        cpu_wr_busy;

    hdmi_video_output hvo (
        .video_clk,
        .rst_n,
        .vga_pclk(),
        .vga_de(),
        .vga_hs(),
        .vga_vs(),
        .vga_rgb(),
        .rowram_rddata(hdmi_rowram_rddata),
        .rowram_rdaddr(hdmi_rowram_rdaddr),
        .palram_rddata(hdmi_palram_rddata),
        .palram_rdaddr(hdmi_palram_rdaddr),
        .rowram_swap,
        .vblank_start,
        .vblank_end_soon
    );

    ppu u_ppu (
        .clk,
        .rst_n,
        .hdmi_rowram_rddata,
        .hdmi_rowram_rdaddr,
        .hdmi_palram_rddata,
        .hdmi_palram_rdaddr,
        .rowram_swap,
        .vblank_start,
        .vblank_end_soon,
        .h2f_vram_wraddr(h2f_vram_wraddr),
        .h2f_vram_wren(h2f_vram_wren),
        .h2f_vram_wrdata(h2f_vram_wrdata),
        .h2f_vram_byteena(h2f_vram_byteena),
        .cpu_vram_wr_irq,
        .cpu_wr_busy
    );

    cpu_dummy_writer dummy_cpu (
        .clk,
        .rst_n,
        .cpu_vram_wr_irq,
        .cpu_wr_busy,
        .h2f_vram_wraddr,
        .h2f_vram_wren,
        .h2f_vram_wrdata,
        .h2f_vram_byteena
    );

    // 50 MHz FPGA clock
    always begin
        clk = 1;
        #10;
        clk = 0;
        #10;
    end

    // 25 MHz Video Clock (supposed to be PLL-generated)
    always begin
        video_clk = 1;
        #20;
        video_clk = 0;
        #20;
    end

    initial begin
        rst_n = 0;
        #1;
        rst_n = 1;
        #1;

        #(16800000 * 2); // Simulate for 2 frames
        $stop;
    end

endmodule : fpgame_video_tb

module cpu_dummy_writer (
    input  logic clk,
    input  logic rst_n,
    input  logic cpu_vram_wr_irq,
    output logic cpu_wr_busy,
    output logic [12:0] h2f_vram_wraddr,
    output logic        h2f_vram_wren,
    output logic [63:0] h2f_vram_wrdata,
    output logic [7:0]  h2f_vram_byteena
);

    enum { DUMMY_IDLE, DUMMY_WRITE } state;

    logic [2:0] wr_counter;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            h2f_vram_wraddr <= 13'b0;
            h2f_vram_wren <= 1'b0;
            h2f_vram_wrdata <= 64'b0;
            h2f_vram_byteena <= 8'b0;
            wr_counter <= 3'b0;
            state <= DUMMY_IDLE;
            cpu_wr_busy <= 1'b0;
        end
        else if (state == DUMMY_IDLE) begin
            h2f_vram_wren <= 1'b0;
            cpu_wr_busy <= 1'b0;
            if (cpu_vram_wr_irq) begin
                cpu_wr_busy <= 1'b1;
                state <= DUMMY_WRITE;
            end
        end
        else if (state == DUMMY_WRITE) begin
            unique case (wr_counter)
                3'b000: begin // Write to beginning of tile ram
                    h2f_vram_wraddr <= 13'h0000;
                    h2f_vram_wren <= 1'b1;
                    h2f_vram_wrdata <= 64'd12345;
                    h2f_vram_byteena <= 8'hFF;
                    wr_counter <= wr_counter + 3'b1;
                end
                3'b001: begin // end of tile ram
                    h2f_vram_wraddr <= 13'h07FF;
                    h2f_vram_wren <= 1'b1;
                    h2f_vram_wrdata <= 64'd12345;
                    h2f_vram_byteena <= 8'hFF;
                    wr_counter <= wr_counter + 3'b1;
                end
                3'b010: begin // beginning of pattern ram
                    h2f_vram_wraddr <= 13'h0800;
                    h2f_vram_wren <= 1'b1;
                    h2f_vram_wrdata <= 64'd12345;
                    h2f_vram_byteena <= 8'hFF;
                    wr_counter <= wr_counter + 3'b1;
                end
                3'b011: begin // end of pattern ram
                    h2f_vram_wraddr <= 13'h17FF;
                    h2f_vram_wren <= 1'b1;
                    h2f_vram_wrdata <= 64'd12345;
                    h2f_vram_byteena <= 8'hFF;
                    wr_counter <= wr_counter + 3'b1;
                end
                3'b100: begin // beginning of palette ram
                    h2f_vram_wraddr <= 13'h1800;
                    h2f_vram_wren <= 1'b1;
                    h2f_vram_wrdata <= 64'd12345;
                    h2f_vram_byteena <= 8'hFF;
                    wr_counter <= wr_counter + 3'b1;
                end
                3'b101: begin // end of palette ram
                    h2f_vram_wraddr <= 13'h19FF;
                    h2f_vram_wren <= 1'b1;
                    h2f_vram_wrdata <= 64'd12345;
                    h2f_vram_byteena <= 8'hFF;
                    wr_counter <= wr_counter + 3'b1;
                end
                3'b110: begin // beginning of sprite ram
                    h2f_vram_wraddr <= 13'h1A00;
                    h2f_vram_wren <= 1'b1;
                    h2f_vram_wrdata <= 64'd12345;
                    h2f_vram_byteena <= 8'hFF;
                    wr_counter <= wr_counter + 3'b1;
                end
                3'b111: begin // end of sprite ram
                    h2f_vram_wraddr <= 13'h1A27;
                    h2f_vram_wren <= 1'b1;
                    h2f_vram_wrdata <= 64'd12345;
                    h2f_vram_byteena <= 8'hFF;

                    //write sequence is done. go back to idle and wait for the next CPU IRQ
                    wr_counter <= 3'b0;
                    state <= DUMMY_IDLE;
                end
            endcase
        end
    end
endmodule : cpu_dummy_writer
