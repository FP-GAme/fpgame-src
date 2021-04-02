module vram_sync_writer (
    input  logic clk,
    input  logic rst_n,
    input  logic sync,
    output logic done,

    // vram output interfaces
    vram_if.usr vram_ifP_usr,
    vram_if.usr vram_ifC_usr
);

// We always sync from VRAM-C (CPU FACING) to VRAM-P (PPU-FACING).

// Since this module never writes to vram_ifC, leave write-related ports as "don't-cares"
assign vram_ifC_usr.tilram_byteena_b = 'X;
assign vram_ifC_usr.patram_byteena_b = 'X;
assign vram_ifC_usr.palram_byteena_b = 'X;
assign vram_ifC_usr.sprram_byteena_b = 'X;

assign vram_ifC_usr.tilram_wrdata_a = 'X;
assign vram_ifC_usr.patram_wrdata_a = 'X;
assign vram_ifC_usr.palram_wrdata_a = 'X;
assign vram_ifC_usr.sprram_wrdata_a = 'X;

assign vram_ifC_usr.tilram_wrdata_b = 'X;
assign vram_ifC_usr.patram_wrdata_b = 'X;
assign vram_ifC_usr.palram_wrdata_b = 'X;
assign vram_ifC_usr.sprram_wrdata_b = 'X;

enum { IDLE, SYNC } state;

logic tilram_sync1_done, patram_sync1_done, palram_sync1_done, sprram_sync1_done; // registers holding "seen" signals
logic tilram_sync2_done, patram_sync2_done, palram_sync2_done, sprram_sync2_done; // registers holding "seen" signals
logic tilram_sync1_done_sig, patram_sync1_done_sig, palram_sync1_done_sig, sprram_sync1_done_sig; // signals wires
logic tilram_sync2_done_sig, patram_sync2_done_sig, palram_sync2_done_sig, sprram_sync2_done_sig; // signals wires

// Tile RAM port 1 synchronizer copies the first half of the Tile RAM's address space.
// Uses only the "a" ports of the dual port tile RAMs
logic [9:0] tilram_sync1_addrP, tilram_sync1_addrC;
sync_writer #(
    .ADDR_WIDTH(10),
    .MAX_ADDR(1023) // 2048 / 2 - 1
) tilram_sync1 (
    .clk,
    .rst_n,
    .sync,
    .done(        tilram_sync1_done_sig),
    .clr_done(1'b0),
    .addr_from(   tilram_sync1_addrC),
    .wren_from(   vram_ifC_usr.tilram_wren_a),
    .rddata_from( vram_ifC_usr.tilram_rddata_a),
    .addr_to(     tilram_sync1_addrP),
    .byteena_to(),
    .wrdata_to(   vram_ifP_usr.tilram_wrdata_a),
    .wren_to(     vram_ifP_usr.tilram_wren_a)
);
assign vram_ifP_usr.tilram_addr_a = {1'b0, tilram_sync1_addrP}; // write to 1st half of address
assign vram_ifC_usr.tilram_addr_a = {1'b0, tilram_sync1_addrC}; // read from 1st half of address

// Tile RAM port 2 synchronizer copies the latter half of the Tile RAM's address space
// Uses only the "b" ports of the dual port tile RAMs
logic [9:0] tilram_sync2_addrP, tilram_sync2_addrC;
sync_writer #(
    .ADDR_WIDTH(10),
    .MAX_ADDR(1023)
) tilram_sync2 (
    .clk,
    .rst_n,
    .sync,
    .done(        tilram_sync2_done_sig),
    .clr_done(1'b0),
    .addr_from(   tilram_sync2_addrC),
    .wren_from(   vram_ifC_usr.tilram_wren_b),
    .rddata_from( vram_ifC_usr.tilram_rddata_b),
    .addr_to(     tilram_sync2_addrP),
    .byteena_to(  vram_ifP_usr.tilram_byteena_b),
    .wrdata_to(   vram_ifP_usr.tilram_wrdata_b),
    .wren_to(     vram_ifP_usr.tilram_wren_b)
);
assign vram_ifP_usr.tilram_addr_b = {1'b1, tilram_sync2_addrP}; // write to 2nd half of address
assign vram_ifC_usr.tilram_addr_b = {1'b1, tilram_sync2_addrC}; // read from 2nd half of address


logic [10:0] patram_sync1_addrP, patram_sync1_addrC;
sync_writer #(
    .ADDR_WIDTH(11),
    .MAX_ADDR(2047) // 4096 / 2 - 1
) patram_sync1 (
    .clk,
    .rst_n,
    .sync,
    .done(        patram_sync1_done_sig),
    .clr_done(1'b0),
    .addr_from(   patram_sync1_addrC),
    .wren_from(   vram_ifC_usr.patram_wren_a),
    .rddata_from( vram_ifC_usr.patram_rddata_a),
    .addr_to(     patram_sync1_addrP),
    .byteena_to(),
    .wrdata_to(   vram_ifP_usr.patram_wrdata_a),
    .wren_to(     vram_ifP_usr.patram_wren_a)
);
assign vram_ifP_usr.patram_addr_a = {1'b0, patram_sync1_addrP};
assign vram_ifC_usr.patram_addr_a = {1'b0, patram_sync1_addrC};

logic [10:0] patram_sync2_addrP, patram_sync2_addrC;
sync_writer #(
    .ADDR_WIDTH(11),
    .MAX_ADDR(2047)
) patram_sync2 (
    .clk,
    .rst_n,
    .sync,
    .done(        patram_sync2_done_sig),
    .clr_done(1'b0),
    .addr_from(   patram_sync2_addrC),
    .wren_from(   vram_ifC_usr.patram_wren_b),
    .rddata_from( vram_ifC_usr.patram_rddata_b),
    .addr_to(     patram_sync2_addrP),
    .byteena_to(  vram_ifP_usr.patram_byteena_b),
    .wrdata_to(   vram_ifP_usr.patram_wrdata_b),
    .wren_to(     vram_ifP_usr.patram_wren_b)
);
assign vram_ifP_usr.patram_addr_b = {1'b1, patram_sync2_addrP};
assign vram_ifC_usr.patram_addr_b = {1'b1, patram_sync2_addrC};


logic [7:0] palram_sync1_addrP, palram_sync1_addrC;
sync_writer #(
    .ADDR_WIDTH(8),
    .MAX_ADDR(255) // 512 / 2 - 1
) palram_sync1 (
    .clk,
    .rst_n,
    .sync,
    .done(        palram_sync1_done_sig),
    .clr_done(1'b0),
    .addr_from(   palram_sync1_addrC),
    .wren_from(   vram_ifC_usr.palram_wren_a),
    .rddata_from( vram_ifC_usr.palram_rddata_a),
    .addr_to(     palram_sync1_addrP),
    .byteena_to(),
    .wrdata_to(   vram_ifP_usr.palram_wrdata_a),
    .wren_to(     vram_ifP_usr.palram_wren_a)
);
assign vram_ifP_usr.palram_addr_a = {1'b0, palram_sync1_addrP};
assign vram_ifC_usr.palram_addr_a = {1'b0, palram_sync1_addrC};

logic [7:0] palram_sync2_addrP, palram_sync2_addrC;
sync_writer #(
    .ADDR_WIDTH(8),
    .MAX_ADDR(255)
) palram_sync2 (
    .clk,
    .rst_n,
    .sync,
    .done(        palram_sync2_done_sig),
    .clr_done(1'b0),
    .addr_from(   palram_sync2_addrC),
    .wren_from(   vram_ifC_usr.palram_wren_b),
    .rddata_from( vram_ifC_usr.palram_rddata_b),
    .addr_to(     palram_sync2_addrP),
    .byteena_to(  vram_ifP_usr.palram_byteena_b),
    .wrdata_to(   vram_ifP_usr.palram_wrdata_b),
    .wren_to(     vram_ifP_usr.palram_wren_b)
);
assign vram_ifP_usr.palram_addr_b = {1'b1, palram_sync2_addrP};
assign vram_ifC_usr.palram_addr_b = {1'b1, palram_sync2_addrC};


logic [4:0] sprram_sync1_addrP, sprram_sync1_addrC;
sync_writer #(
    .ADDR_WIDTH(5),
    .MAX_ADDR(31) // 64/2 - 1
) sprram_sync1 (
    .clk,
    .rst_n,
    .sync,
    .done(        sprram_sync1_done_sig),
    .clr_done(1'b0),
    .addr_from(   sprram_sync1_addrC),
    .wren_from(   vram_ifC_usr.sprram_wren_a),
    .rddata_from( vram_ifC_usr.sprram_rddata_a),
    .addr_to(     sprram_sync1_addrP),
    .byteena_to(),
    .wrdata_to(   vram_ifP_usr.sprram_wrdata_a),
    .wren_to(     vram_ifP_usr.sprram_wren_a)
);
assign vram_ifP_usr.sprram_addr_a = {1'b0, sprram_sync1_addrP};
assign vram_ifC_usr.sprram_addr_a = {1'b0, sprram_sync1_addrC};

logic [4:0] sprram_sync2_addrP, sprram_sync2_addrC;
sync_writer #(
    .ADDR_WIDTH(5),
    .MAX_ADDR(7)
) sprram_sync2 (
    .clk,
    .rst_n,
    .sync,
    .done(        sprram_sync2_done_sig),
    .clr_done(1'b0),
    .addr_from(   sprram_sync2_addrC),
    .wren_from(   vram_ifC_usr.sprram_wren_b),
    .rddata_from( vram_ifC_usr.sprram_rddata_b),
    .addr_to(     sprram_sync2_addrP),
    .byteena_to(  vram_ifP_usr.sprram_byteena_b),
    .wrdata_to(   vram_ifP_usr.sprram_wrdata_b),
    .wren_to(     vram_ifP_usr.sprram_wren_b)
);
assign vram_ifP_usr.sprram_addr_b = {1'b1, sprram_sync2_addrP};
assign vram_ifC_usr.sprram_addr_b = {1'b1, sprram_sync2_addrC};


assign done = (tilram_sync1_done & patram_sync1_done & palram_sync1_done & sprram_sync1_done &
               tilram_sync2_done & patram_sync2_done & palram_sync2_done & sprram_sync2_done);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        //reset state and control signals
        state <= IDLE;
        {tilram_sync1_done, patram_sync1_done, palram_sync1_done, sprram_sync1_done} <= 4'b0;
        {tilram_sync2_done, patram_sync2_done, palram_sync2_done, sprram_sync2_done} <= 4'b0;
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
                if (tilram_sync1_done_sig) tilram_sync1_done <= 1'b1;
                if (tilram_sync2_done_sig) tilram_sync2_done <= 1'b1;
                if (patram_sync1_done_sig) patram_sync1_done <= 1'b1;
                if (patram_sync2_done_sig) patram_sync2_done <= 1'b1;
                if (palram_sync1_done_sig) palram_sync1_done <= 1'b1;
                if (palram_sync2_done_sig) palram_sync2_done <= 1'b1;
                if (sprram_sync1_done_sig) sprram_sync1_done <= 1'b1;
                if (sprram_sync2_done_sig) sprram_sync2_done <= 1'b1;

                // if all writes are done, exit to idle and assert sync signal
                if (done) begin
                    state <= IDLE;
                    // reset done state:
                    {tilram_sync1_done, patram_sync1_done, palram_sync1_done, sprram_sync1_done} <= 4'b0;
                    {tilram_sync2_done, patram_sync2_done, palram_sync2_done, sprram_sync2_done} <= 4'b0;
                end
            end
        endcase
    end
end

endmodule : vram_sync_writer
