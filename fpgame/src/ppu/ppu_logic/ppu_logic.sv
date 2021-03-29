/* ppu_logic.sv
 * TODO: Joseph... plz document.
 */

module ppu_logic (
    input logic clk,
    input logic rst_n,

    // from/to HDMI video output
    output logic [9:0]  rowram_rddata,
    input  logic [8:0]  rowram_rdaddr,
    output logic [63:0] palram_rddata,
    input  logic [8:0]  palram_rdaddr,
    input  logic        rowram_swap,
    
    output logic [5:0]  LED, // TODO: Remove after debug

    vram_if.usr vram_ppu_ifP_usr
);

    // TODO instantiate 2 Tile-Engines, 1 Sprite Engine, 1 Pixel Mixer.
    // TODO Figure out whether row ram should be here or in ppu.sv

    // TODO: Move into ppu_logic eventually?
    // TODO: This should be a row-ram interface. In reality, 2 row-rams should exist. One for the PPU-logic to write to, and one for the hdmi_video_output to read from
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

    ppu_debug_reader pdr (
        .clk,
        .rst_n,
        .LED,
        .palram_rddata,
        .palram_rdaddr,
        .vram_ppu_ifP_usr(vram_ppu_ifP_usr)
    );

    //assign palram_rddata = vram_ppu_ifP_usr.palram_rddata_a; // TODO: Check over later
    //assign vram_ppu_ifP_usr.palram_addr_a = palram_rdaddr;   // TODO: Also check over later

endmodule : ppu_logic

module ppu_debug_reader (
    input  logic clk,
    input  logic rst_n,
    output logic [5:0] LED, // TODO: Remove after debug
    output logic [63:0] palram_rddata,
    input  logic [8:0]  palram_rdaddr,
    vram_if.usr vram_ppu_ifP_usr
);
    // TODO: Remove these. These don't belong here, but in PPU-Logic
    assign palram_rddata = vram_ppu_ifP_usr.palram_rddata_a; // TODO: Check over later
    assign vram_ppu_ifP_usr.palram_addr_a = palram_rdaddr;   // TODO: Also check over later
    assign vram_ppu_ifP_usr.palram_wren_a = 1'b0;
    assign vram_ppu_ifP_usr.palram_wrdata_a = 64'b0;
    assign vram_ppu_ifP_usr.palram_addr_b = 9'b0;
    assign vram_ppu_ifP_usr.palram_wren_b = 1'b0;
    assign vram_ppu_ifP_usr.palram_wrdata_b = 64'b0;
    assign vram_ppu_ifP_usr.palram_byteena_b = 8'b0;

    logic [5:0] rd_data_correct;

    // Default assignments for write data we do not use
    assign vram_ppu_ifP_usr.tilram_wren_a = 1'b0;
    assign vram_ppu_ifP_usr.tilram_wren_b = 1'b0;
    assign vram_ppu_ifP_usr.tilram_wrdata_a = 64'b0;
    assign vram_ppu_ifP_usr.tilram_wrdata_b = 64'b0;
    assign vram_ppu_ifP_usr.tilram_byteena_b = 8'b0;

    assign vram_ppu_ifP_usr.patram_wren_a = 1'b0;
    assign vram_ppu_ifP_usr.patram_wren_b = 1'b0;
    assign vram_ppu_ifP_usr.patram_wrdata_a = 64'b0;
    assign vram_ppu_ifP_usr.patram_wrdata_b = 64'b0;
    assign vram_ppu_ifP_usr.patram_byteena_b = 8'b0;

    assign vram_ppu_ifP_usr.sprram_wren_a = 1'b0;
    assign vram_ppu_ifP_usr.sprram_wren_b = 1'b0;
    assign vram_ppu_ifP_usr.sprram_wrdata_a = 64'b0;
    assign vram_ppu_ifP_usr.sprram_wrdata_b = 64'b0;
    assign vram_ppu_ifP_usr.sprram_byteena_b = 8'b0;

    // Assign the hard-coded watch/read locations
    assign vram_ppu_ifP_usr.tilram_addr_a = 11'd0;
    assign vram_ppu_ifP_usr.tilram_addr_b = 11'd2047;
    assign vram_ppu_ifP_usr.patram_addr_a = 12'd0;
    assign vram_ppu_ifP_usr.patram_addr_b = 12'd4095;
    assign vram_ppu_ifP_usr.sprram_addr_a =  6'd0;
    assign vram_ppu_ifP_usr.sprram_addr_b =  6'd39;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            rd_data_correct = 6'b0;
        end
        else begin
            if (vram_ppu_ifP_usr.tilram_rddata_a == 64'd12345) begin
                rd_data_correct[0] <= 1'b1;
            end
            if (vram_ppu_ifP_usr.tilram_rddata_b == 64'd12345) begin
                rd_data_correct[1] <= 1'b1;
            end
            if (vram_ppu_ifP_usr.patram_rddata_a == 64'd12345) begin
                rd_data_correct[2] <= 1'b1;
            end
            if (vram_ppu_ifP_usr.patram_rddata_b == 64'd12345) begin
                rd_data_correct[3] <= 1'b1;
            end
            if (vram_ppu_ifP_usr.sprram_rddata_a == 64'd12345) begin
                rd_data_correct[4] <= 1'b1;
            end
            if (vram_ppu_ifP_usr.sprram_rddata_b == 64'd12345) begin
                rd_data_correct[5] <= 1'b1;
            end
        end
    end

    assign LED[5:0] = rd_data_correct;
endmodule : ppu_debug_reader