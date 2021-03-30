/* pixel_mixer.sv
 * Implements the Pixel Mixer
 */
/* Overview
 * The Pixel Mixer idles until all Pixel-Engines raise a done signal (this will always occur a
 *   constant # of cycles after the rowbuffer swap signal has been received).
 * Then, for each of the 320 pixels in a row, the Pixel Mixer will ask the Pixel Engines (BG-Tile,
 *   FG-Tile, and Sprite), for the following information in parallel:
 * 1. A 4-bit color for the pixel.
 * 2. A 4-bit palette address for the pixel (relative to the Pixel Engine's base address in Palette
 *    RAM).
 * 3. Just for the Sprite Engine: A 2-bit priority encoded as follows:
 *    * 00 for behind BG,
 *    * 01 for behind FG,
 *    * 1X for in front of both FG and BG
 *
 * To achieve this, the Pixel Engines are given the current pixel's column (0-319). They must
 *   respond with the data on the next clock cycle (behaving exactly like a On-Chip RAM).
 * 
 * The Pixel Mixer receives this information and chooses the final 10-bit pixel data to write to the
 *   rowbuffer. For more information on this logic, see the pixel_priority module.
 *
 * The final 10-bit pixel data has the following format:
 * * 4-bit color address into palette
 * * 4-bit palette address into Palette RAM
 * * 2-bit source address (00 BG Palette, 01 FG Palette, or 1X Sprite Palette)
 */

module pixel_mixer (
    // from/to Pixel-Engines
    output logic [8:0] pixel_addr,
    input  logic [7:0] fg_pixel_data,
    input  logic [7:0] bg_pixel_data,
    input  logic [7:0] sp_pixel_data,
    input  logic       done
);

endmodule : pixel_mixer