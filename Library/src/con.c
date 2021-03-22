/**
 * @file con.c
 * @author Andrew Spaulding
 * @brief Implementation of the user controller driver interface.
 */

#include <FP-GAme/con.h>

#include <sys/ioctl.h>
#include <ioctl_con.h>
#include <fcntl.h>
#include <unistd.h>

#include <stdlib.h>
#include <stdbool.h>

#include <noway.h>

/**
 * @brief The device file descriptor.
 *
 * Upon the first call to get_con_state, the function will attempt
 * to open the device file and store its fd here. The fd will be
 * closed by a function registered to atexit().
 *
 * Note that if close() fails or the program terminates abnormally
 * after atexit() succedes the fd may not be correctly closed. There
 * is little we can do about this, so we assume the kernel will deal
 * with it and move on with our lives.
 */
static int dev_file_fd = -1;

/* Helper functions */
void con_cleanup(void);

int get_con_state(void)
{
	/* Open the device file, if it isn't already. */
	bool close_fd = false;
	if (dev_file_fd < 0) {
		dev_file_fd = open(CON_DEV_FILE, 0);
		if (dev_file_fd < 0) { return -1; }
		close_fd = (atexit(con_cleanup) < 0);
	}

	/* Ask the controller driver for the current state. */
	int ret = ioctl(dev_file_fd, IOCTL_CON_GET_STATE);

	/* If atexit failed, we have to cleanup. */
	if (close_fd) { con_cleanup(); }

	return ret;
}

/**
 * @brief Closes the device file descriptor.
 */
void con_cleanup(void)
{
	noway(dev_file_fd < 0);
	close(dev_file_fd);
	dev_file_fd = -1;
}
