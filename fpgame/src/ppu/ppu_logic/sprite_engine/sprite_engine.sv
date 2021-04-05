/* sprite_engine.sv
 * Implements the Sprite-Engine.
 */

module sprite_engine (
    input  logic clk,
    input  logic rst_n,

    // From ppu_logic (and technically hdmi_video_output)
    input  logic [7:0]  next_row,       // The row we should prepare to display
    output logic [10:0] sprram_addr,    // Address to Sprite-RAM
    input  logic [63:0] sprram_rddata,  // Read-data from Sprite-RAM
    // TODO: Technically you can have 2 Sprite-RAM read ports available to you. Let me know if you
    //       want to use the extra one for speeding up reads. You likely won't need to, though.
    output logic [11:0] patram_addr,    // Address to Pattern-RAM
    input  logic [63:0] patram_rddata,  // Read-data from Pattern-RAM
    // TODO: Technically you can have 2 pattern RAM read ports available to you. Let me know if you
    //       want to use the extra one for speeding up reads. You likely won't need to, though
    input  logic        prep,            // Start preparing a row corresponding to next_row

    // From Double-Buffered Control Registers
    input  logic        enable,

    // from/to Pixel Mixer
    input  logic [8:0]  pmxr_pixel_addr,
    output logic [7:0]  pmxr_pixel_data,
    output logic        done
);

// TODO: Implement sprite_engine

endmodule : sprite_engine