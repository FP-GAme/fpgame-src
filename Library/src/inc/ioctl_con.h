/**
 * @file ioctl_con.h
 * @author Andrew Spaulding
 * @brief IOCTL macros necessary for using the controller driver.
 */

#ifndef _FP_GAME_IOCTL_CON_H_
#define _FP_GAME_IOCTL_CON_H_

#include <linux/ioctl.h>

/**
 * @brief The major number for the controller driver.
 *        We set it up as an HID.
 */
#define CON_MAJOR_NUM 'H'

/** @brief The IOCTL command which reads the current controller input. */
#define IOCTL_CON_GET_STATE _IO(CON_MAJOR_NUM, 0)

/** @brief The device file used to access the controller driver. */
#define CON_DEV_FILE "fp_game_controller"

#endif /* _FP_GAME_IOCTL_CON_H_ */
