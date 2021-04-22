/* sprite_engine.sv
 * Implements the Sprite-Engine.
 */

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

/* TODO START: Implement sprite_engine. Remove these messages (if you want)

Important Interface Details:

You have around 2800 clock cycles to Prepare for the pixel mixer.
Any time leftover can be spent mining bitcoin.

When you assert the done signal, this module must be ready to accept pmxr_pixel_addr, and spit data
  out on pmxr_pixel_data and pmxr_pixel_prio a clock cycle after.

To visualize this timing:
--- Assert done signal ---
--- some number of rising clk edges later ---

--- pmxr sets pmxr_pixel_addr 0 ---
--- rising clk edge ---

--- Sprite engine sees pmxr_pixel_addr 0 ---
--- pmxr sets pmxr_pixel_addr 1 ---
--- rising clk edge ---

--- Sprite engine sees pmxr_pixel_addr 1 ---
--- pmxr sets pmxr_pixel_addr 2 ---
--- Sprite Engine spits out pmxr_data corresponding to pmxr_pixel_addr 0 ---
--- rising clk edge ---

... and so on ...

If this is confusing. See the diagram I sent over Slack.

TODO END: Good luck!
*/

// TODO: Remove these placeholders
assign done = 1'b1;
assign pmxr_pixel_prio = 2'b10;
assign pmxr_pixel_data = 9'd0;
assign patram_addr = 12'd0;
assign sprram_addr_a = 6'd0;
assign sprram_addr_b = 6'd0;

endmodule : sprite_engine