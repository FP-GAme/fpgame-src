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

	input  sprite_conf_t conf,
	input  logic conf_ack,
	output logic conf_req,

	input  pixel_t [7:0] pattern,
	input  logic pattern_avail,
	output logic [12:0] pattern_addr,
	output logic pattern_read,

	output sprite_reg_t sprite;
	output logic sprite_valid;
	input  logic sprite_ack;
);

/*** Wires ***/

enum logic [1:0] { CONF_READ, PAT_READ, SEND_SPRITE } state, next_state;

sprite_conf_t sprite_conf, next_sprite_conf;
pixel_t [3:0][7:0] pat_buf, next_pat_buf;

logic [2:0] read_req_count, read_ack_count;
logic read_req_inc, read_ack_inc, counter_clear;

/*** Modules ***/

sprite_addr_gen addr_gen(.conf, .row, .addr(pattern_addr), .index(read_ack_count));

counter #(3) req_cnt(.clock, .reset_l, .inc(read_req_inc),
                     .out(read_req_count), .clear(counter_clear));

counter #(3) ack_cnt(.clock, .reset_l, .inc(read_ack_inc),
                     .out(read_ack_count), .clear(counter_clear));

/*** Combonational Logic ***/

assign read_ack_inc = pattern_avail;

assign sprite.pat = pat_buf;
assign sprite.conf.palette = sprite_conf.palette;
assign sprite.conf.x = sprite_conf.x
assign sprite.conf.w = sprite_conf.w
assign sprite.conf.x_mirror = sprite_conf.x_mirror;
assign sprite.conf.fg_prio = sprite_conf.fg_prio;
assign sprite.conf.bg_prio = sprite_conf.bg_prio;

always_comb begin
	next_sprite_conf = sprite_conf;
	next_pat_buf = pat_buf;
	counter_clear = 'd0;
	conf_req = 'd0;
	pattern_read = 'd0;
	read_req_inc = 'd0;
	sprite_valid = 'd0;

	unique case (state)
	CONF_READ: begin
		counter_clear = 'd1;
		conf_req = 'd1;

		next_state = (conf_ack) ? PAT_READ : CONF_READ;
		next_sprite_conf = (conf_ack) ? conf : sprite_conf;
	end
	PAT_READ: begin
		pattern_read = (read_req_count <= { 1'b0, sprite_conf.w });
		read_req_inc = pattern_read;
		next_pat_buf[read_ack_count] = (pattern_avail) ? pattern
		                             : pat_buf[read_ack_count];
		next_state = (read_ack_count > {1'b0, sprite_conf.w})
		           ? SEND_SPRITE : PAT_READ;
	end
	SEND_SPRITE: begin
		sprite_valid = 'd1;
		next_state = (sprite_ack) ? CONF_READ : SEND_SPRITE;
	end
end

/*** Sequential Logic ***/

always_ff @(posedge clock, negedge reset_l) begin
	if (~reset_l | clear) begin
		sprite_conf <= 'd0;
		sprite <= 'd0;
		conf_req <= 'd0;
		state <= CONF_READ;
	end else begin
		sprite_conf <= next_sprite_conf;
		sprite <= next_sprite;
		conf_req <= next_conf_req;
		state <= next_state;
	end
end

endmodule : sprite_manager
