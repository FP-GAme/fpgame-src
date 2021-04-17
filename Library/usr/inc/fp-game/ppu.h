/** @file ppu.h
 * @author Joseph Yankel
 * @brief User Library for the FP-GAme PPU
 *
 * TODO: Write Description
 * @attention: Modifications to the PPU will not be accepted during certain busy states managed by
 * the Kernel. Any functions which attempt to modify PPU data will return -1 if the modification
 * could not be made. You are encouraged to poll these functions until they return 0 (success) if
 * you want to ensure your changes are made.
 */

// TODO: Yeah, to make this truly nice, we need another VRAM buffer and some control register buffers... LOL

#ifndef _FP_GAME_PPU_H_
#define _FP_GAME_PPU_H_

#include <stdlib.h>

/** @brief Enables the PPU
 *
 * Attempts to lock PPU access to this process. If successful, only this process will be able to
 *   write to the PPU.
 *
 * Fails if the PPU is already owned by another process.
 *
 * The caller of this function must call ppu_disable before program exit to prevent resource leaks.
 *
 * @return 0 on success; -1 on error
 */
int ppu_enable(void);

/** @brief Disables the PPU
 *
 * Releases the lock on the PPU. Other processes will be able to reserve access to the PPU.
 *
 * It is illegal to call this function if the PPU is not currently enabled and owned by the calling
 * process.
 */
void ppu_disable(void);

/** @brief Requests for the current frame changes to be send to the PPU on the next available frame
 *
 * Any previous calls to ppu_set_[...] functions are guaranteed to take effect after this function
 *   returns successfully.
 *
 * If you want to ensure your frame gets sent out to the PPU, and also want to synchronize to the
 *   PPU's internal 60FPS timing, keep polling this function until 0 (success) is returned.
 *
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_update(void);

/** @brief Writes directly to the VRAM buffer 
 *
 * @attention This gives a lower-level access to the VRAM buffer! See the higher-level write
 * functions such as ppu_write_tile or ppu_write_sprite. TODO: Come back to this later Joseph.
 *
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_write_vram(const void *buf, size_t len);

/** @brief Sets the universal background color of the PPU
 *
 * The universal background color is the color displayed when all PPU render layers are transparent.
 *
 * This function will set this color to be displayed at the next ppu_update().
 *
 * @remark Any higher-order bits [31:24] in color will be ignored!
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param color 32-bit color holding a 24-bit RRGGBB hex color value. For example, 0xFF0000 for red.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_set_bgcolor(unsigned color);

/** @brief Enables or disables one or more of the three PPU render layers using a bit-mask
 *
 * The enable mask has three bits which enable or disable the PPU render layers as follows:
 * Bit 0: Enable (1) or disable (0) the background tile layer
 * Bit 1: Enable (1) or disable (0) the foreground tile layer
 * Bit 2: Enable (1) or disable (0) the sprite layer
 *
 * Call this function before an ppu_update() to ensure the layer will be enabled on the next frame.
 *
 * @remark Any higher-order bits in enable_mask not specified above will be ignored!
 * @pre PPU is currently locked by this process. See @ref ppu_enable.
 * @param enable_mask Bit-mask used to enable/disable PPU rendering layers.
 * @return 0 on success; -1 if PPU busy
 */
int ppu_set_layer_enable(unsigned char enable_mask);

#endif /* _FP_GAME_PPU_H_ */