/*
 * File: sprite_engine.sv
 * Author: Joseph Yankel
 * Author: Andrew Spaulding
 *
 * Implements the Sprite-Engine.
 */

`include "sprite_defines.vh"

module sprite_engine (
    input  logic clk,
    input  logic rst_n,

    // From ppu_logic (and technically hdmi_video_output)
    input  logic [7:0]  next_row,        // The row we should prepare to display
    output logic [5:0]  sprram_addr_a,   // Address to Sprite-RAM port a
    input  logic [63:0] sprram_rddata_a, // Read-data from Sprite-RAM port b
    output logic [5:0]  sprram_addr_b,   // Address to Sprite-RAM port b
    input  logic [63:0] sprram_rddata_b, // Read-data from Sprite-RAM port b
    output logic [11:0] patram_addr,     // Address to Pattern-RAM
    input  logic [63:0] patram_rddata,   // Read-data from Pattern-RAM
    input  logic        prep,            // Start preparing a row corresponding to next_row

    // From Double-Buffered Control Registers
    input  logic        enable,

    // from/to Pixel Mixer
    input  logic [8:0]  pmxr_pixel_addr,
    output logic [8:0]  pmxr_pixel_data, // 5b palette address (relative to sprite section), 4b color
    output logic [1:0]  pmxr_pixel_prio, // Priority of the pixel
    output logic        done
);

/*** Wires ***/

logic [8:0] col, pixel_addr;
logic [1:0] pixel_prio;
logic clock, reset_l, clear, ready;

logic [7:0] row, next_row_for_real_this_time;
logic last_prep;

logic [12:0] pattern_addr;
pixel_t [7:0] pattern_data;
logic pattern_read, pattern_avail;

logic [6:0] oam_addr;
sprite_conf_t oam_data;
logic oam_read, oam_avail;

logic conf_req, conf_ack, conf_exists;

sprite_reg_t sprite;
logic sprite_valid, sprite_ack;

/*** Modules ***/

pattern_wrapper pat_wrap(.clock, .reset_l, .patram_addr, .patram_rddata,
                         .pattern_addr, .pattern_data, .pattern_read,
			 .pattern_avail);

oam_wrapper oam_wrap(.clock, .reset_l, .sprram_addr_a, .sprram_addr_b,
                     .sprram_rddata_a, .sprram_rddata_b, .oam_addr,
		     .oam_data, .oam_read, .oam_avail);

oam_scanner oam_scan(.clock, .reset_l, .clear, .row, .oam_addr, .oam_data,
                     .oam_read, .oam_avail, .conf_req, .conf_ack, .conf_exists,
		     .start(clear));

sprite_manager spr_man(.clock, .reset_l, .clear, .row, .ready, .conf_req,
                       .conf_ack, .conf_exists, .conf(oam_data), .pattern_addr,
		       .pattern_data, .pattern_read, .pattern_avail, .sprite,
		       .sprite_valid, .sprite_ack);

sprite_file spr_file(.clock, .reset_l, .clear, .in(sprite),
                     .in_valid(sprite_valid), .in_ack(sprite_ack),
		     .col, .pixel_addr, .pixel_prio);

/*** Combonational Logic ***/

assign clock = clk;
assign reset_l = rst_n;
assign clear = prep & ~last_prep;
assign done = ready;

assign next_row_for_real_this_time = (prep & ~last_prep) ? next_row : row;

assign pmxr_pixel_data = (enable) ? pixel_addr : 'd0;
assign pmxr_pixel_prio = pixel_prio;

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		col <= 'd0;
		row <= 'd0;
		last_prep <= 'd0;
	end else begin
		col <= pmxr_pixel_addr;
		row <= next_row_for_real_this_time;
		last_prep <= prep;
	end
end

endmodule : sprite_engine
