/**
 * @file drv_con.h
 * @author Andrew Spaulding
 * @brief IOCTL macros necessary for using the controller driver.
 */

#ifndef _FP_GAME_DRV_CON_H_
#define _FP_GAME_DRV_CON_H_

#include <linux/ioctl.h>

/**
 * @brief The major number for the controller driver.
 *
 * Since we're using IOCTL, we can't have our number dynamically registered.
 * A list of numbers in use is available at:
 * https://www.kernel.org/doc/html/latest/userspace-api/ioctl/ioctl-number.html
 *
 * We select 0x1FA-0x1FC for our drivers, with the controller taking 0x1FC.
 */
#define CON_MAJOR_NUM 0x1FC

/** @brief The IOCTL command which reads the current controller input. */
#define IOCTL_CON_GET_STATE _IO(CON_MAJOR_NUM, 0)

/** @brief The device file used to access the controller driver. */
#define CON_DEV_FILE "/dev/fp_game_con"

#endif /* _FP_GAME_DRV_CON_H_ */
