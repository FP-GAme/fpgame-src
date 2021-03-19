/* The number of clock ticks which happen in 1/60th of a second. */
`define PERIOD_60HZ 833333

/* The clock cycle widths of each level in our clock dividers period. */
`define LEVEL_WIDTH_SNES 300

module snes_controller
(
	input logic con_serial,
	input logic clock,
	input logic reset,
	output logic con_clock,
	output logic con_latch,
	output logic [15:0] con_state
);

/* States in the controller protocol FSM. */
enum { INIT, WAIT_CLOCK, PULSE, SAMPLE } state, next_state;

/* Counter used to determine if its time to leave the sample state. */
logic [3:0] next_sample_counter, sample_counter;

/* Used to poll the controller regularly. */
logic tick60;
timer #(`PERIOD_60HZ) (.clock, .reset, .tick(tick60));

/* Used to create the controller protocol clock. */
logic pos_change, neg_change, div_clk;
clock_div #(`LEVEL_WIDTH_SNES) (.clock, .reset, .pos_change,
		.neg_change, .div_clk);

/* Used to hold incoming controller input. */
logic [15:0] new_input;
logic sample_en, finish;
shift_reg #(16) (.clock, .reset, .ld_en(sample_en), .in(con_serial),
		.out(new_input));

logic [15:0] next_con_state;

/* Next state logic for controller protocol FSM */
always_comb begin
	con_latch = 1'b0;
	con_clock = 1'b1;
	next_sample_counter = sample_counter;
	next_con_state = con_state;
	sample_en = 1'b0;
	finish = 1'b0;

	unique case (state)
	INIT:
		next_state = (tick60) ? WAIT_CLOCK : INIT;
	WAIT_CLOCK:
		next_state = (pos_change) ? PULSE : WAIT_CLOCK;
	PULSE: begin
		next_state = (pos_change) ? SAMPLE : PULSE;
		con_latch = 1'b1;
	end
	SAMPLE: begin
		next_sample_counter = (pos_change) ? sample_counter + 4'd1
				: sample_counter;

		finish = (next_sample_counter == 0) && pos_change;
		next_state = (finish) ? INIT : SAMPLE;
		next_con_state = (finish) ? new_input : con_state;

		con_clock = div_clk;
		sample_en = neg_change;
	end
	endcase
end

always_ff @(posedge clock, negedge reset) begin
	if (~reset) begin
		state <= INIT;
		sample_counter <= 4'd0;
		con_state <= 16'd0;
	end else begin
		state <= next_state;
		sample_counter <= next_sample_counter;
		con_state <= next_con_state;
	end
end

endmodule : snes_controller
