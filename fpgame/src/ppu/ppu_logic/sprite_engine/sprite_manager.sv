/*
 * File: sprite_manager.sv
 * Author: Andrew Spaulding
 *
 * Accepts sprites and patterns from the OAM logic, and then provides them
 * to the chain of sprite units.
 */

`include "sprite_defines.vh"

module sprite_manager
(
	input  logic clock, reset_l, clear,

	input  logic [7:0] row,
	output logic ready,

	input  sprite_conf_t conf,
	input  logic conf_ack,
	input  logic conf_exists,
	output logic conf_req,

	input  pixel_t [7:0] pattern_data,
	input  logic pattern_avail,
	output logic [12:0] pattern_addr,
	output logic pattern_read,

	output sprite_reg_t sprite,
	output logic sprite_valid,
	input  logic sprite_ack
);

/*** Wires ***/

enum logic [1:0] { CONF_READ, PAT_READ, SEND_SPRITE } state, next_state;

sprite_conf_t sprite_conf, next_sprite_conf;
pixel_t [3:0][7:0] pat_buf, next_pat_buf;

logic [2:0] read_req_count, read_ack_count;
logic read_req_inc, read_ack_inc, pat_cnt_clear;

logic [4:0] sprite_count;
logic sprite_inc;

/*** Modules ***/

sprite_addr_gen addr_gen(.conf, .row, .addr(pattern_addr), .index(read_ack_count));

counter #(3) req_cnt(.clock, .reset_l, .inc(read_req_inc),
                     .out(read_req_count), .clear(pat_cnt_clear | clear));

counter #(3) ack_cnt(.clock, .reset_l, .inc(read_ack_inc),
                     .out(read_ack_count), .clear(pat_cnt_clear | clear));

counter #(5) spr_cnt(.clock, .reset_l, .clear,
                     .inc(sprite_inc), .out(sprite_count));

/*** Combonational Logic ***/

assign sprite.pat = pat_buf;
assign sprite.conf.palette = sprite_conf.palette;
assign sprite.conf.x = sprite_conf.x;
assign sprite.conf.w = sprite_conf.w;
assign sprite.conf.x_mirror = sprite_conf.x_mirror;
assign sprite.conf.fg_prio = sprite_conf.fg_prio;
assign sprite.conf.bg_prio = sprite_conf.bg_prio;

always_comb begin
	ready = 1'b0;
	next_sprite_conf = (clear) ? 'd0 : sprite_conf;
	next_pat_buf = pat_buf;
	pat_cnt_clear = 'd0;
	conf_req = 'd0;
	pattern_read = 'd0;
	read_req_inc = 'd0;
	read_ack_inc = 'd0;
	sprite_valid = 'd0;
	sprite_inc = 'd0;

	unique case (state)
	CONF_READ: begin
		ready = (~conf_exists
		      || (sprite_count == `MAX_SPRITES_PER_LINE));
		pat_cnt_clear = 'd1;
		conf_req = ~ready;

		next_state = (conf_ack & ~clear) ? PAT_READ : CONF_READ;
		next_sprite_conf = (clear) ? 'd0
		                 : ((conf_ack) ? conf : sprite_conf);
	end
	PAT_READ: begin
		pattern_read = (read_req_count <= { 1'b0, sprite_conf.w });
		read_req_inc = pattern_read;
		read_ack_inc = pattern_avail;
		next_pat_buf[read_ack_count] = (pattern_avail) ? pattern_data
		                             : pat_buf[read_ack_count];
		next_state = (clear) ? CONF_READ
		           : ((read_ack_count > {1'b0, sprite_conf.w})
		           ? SEND_SPRITE : PAT_READ);
	end
	SEND_SPRITE: begin
		sprite_valid = 'd1;
		sprite_inc = sprite_ack;
		next_state = (sprite_ack | clear) ? CONF_READ : SEND_SPRITE;
	end
	endcase
end

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l) begin
		sprite_conf <= 'd0;
		pat_buf <= 'd0;
		state <= CONF_READ;
	end else begin
		sprite_conf <= next_sprite_conf;
		pat_buf <= next_pat_buf;
		state <= next_state;
	end
end

endmodule : sprite_manager
