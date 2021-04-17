/**@file drv_ppu.h
 * @brief Character Device File Information for both Kernel Module and User Library
 * @author Joseph Yankel
 */

#ifndef _FP_GAME_DRV_PPU_H_
#define _FP_GAME_DRV_PPU_H_

#include <linux/ioctl.h>
#include <linux/types.h>

/**@brief The major number for the PPU driver.
 *
 * Since we're using IOCTL, we can't have our number dynamically registered.
 * A list of numbers in use is available at:
 * https://www.kernel.org/doc/html/latest/userspace-api/ioctl/ioctl-number.html
 *
 * We select 0x1FA-0x1FC for our drivers, with the PPU taking 0x1FB.
 */
#define PPU_MAJOR_NUM 0x1FB

/* === Definitions === */
/**@brief PPU device Name */
#define PPU_DEV_NAME     "fp_game_ppu"

/**@brief The device files used to access the PPU driver. */
#define PPU_DEV_FILE ("/dev/" PPU_DEV_NAME)

/**@brief The IOCTL command which informs the driver of the owners PID. */
#define IOCTL_PPU_UPDATE        _IO(PPU_MAJOR_NUM, 0)
#define IOCTL_PPU_SET_BGSCROLL _IOW(PPU_MAJOR_NUM, 1, u_int32_t)
#define IOCTL_PPU_SET_FGSCROLL _IOW(PPU_MAJOR_NUM, 2, u_int32_t)
#define IOCTL_PPU_SET_BGCOLOR  _IOW(PPU_MAJOR_NUM, 3, u_int32_t)
#define IOCTL_PPU_SET_ENABLE   _IOW(PPU_MAJOR_NUM, 4, u_int8_t)

// Size of VRAM in Bytes. Do not write past VRAM_SIZE-1
#define VRAM_SIZE 0xD140

#endif /* _FP_GAME_DRV_PPU_H_ */
