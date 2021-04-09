/**
 * @file drv_apu.h
 * @author Andrew Spaulding
 * @brief IOCTL macros necessary for using the controller driver.
 */

#ifndef _FP_GAME_DRV_APU_H_
#define _FP_GAME_DRV_APU_H_

#include <linux/ioctl.h>
#include <sys/types.h>
#include <signal.h>

/**
 * @brief The major number for the apu driver.
 *
 * Since we're using IOCTL, we can't have our number dynamically registered.
 * A list of numbers in use is available at:
 * https://www.kernel.org/doc/html/latest/userspace-api/ioctl/ioctl-number.html
 *
 * We select 0x1FA-0x1FC for our drivers, with the apu taking 0x1FA.
 */
#define APU_MAJOR_NUM 0x1FA

/** @brief The IOCTL command which informs the driver of the owners PID. */
#define IOCTL_APU_SET_CALLBACK_PID _IOR(APU_MAJOR_NUM, 0, pid_t)

/** @brief The signal which is used to launch the callback function. */
#define APU_CALLBACK_SIG SIGRTMAX

/** @brief The device file used to access the apu driver. */
#define APU_DEV_FILE "/dev/fp_game_apu"

#endif /* _FP_GAME_DRV_APU_H_ */
