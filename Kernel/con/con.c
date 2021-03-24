/**
 * @file con.c
 * @brief Kernel module for the FP-GAme controller
 * @author Andrew Spaulding
 *
 * This kernel module implements the interface to the FP-GAme controller.
 * Calls will be made to it by the user-space FP-GAme library.
 *
 * The only system call which we implement is ioctl. Its return value gives
 * the current controller state.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>

#include <fp-game/drv_con.h>

/* Functions */
int con_init(void);
int con_ioctl(struct inode *inode, struct file *file,
              unsigned ioctl_num, unsigned long ioctl_param);
int con_clean(void);

/**
 * @brief File operations structure.
 *
 * This structure is used to inform the linux kernel which system calls our
 * device driver implements.
 */
struct file_operations fops = {
	.ioctl = con_ioctl
};

/**
 * @brief Initializes the controller kernel module.
 * @return 0 on success, and a negative integer on failure.
 */
int con_init(void)
{
	int ret = register_chrdev(CON_MAJOR_NUM, CON_DEV_NAME, &fops);

	if (ret < 0) {
		printk(KERN_ALERT "Initializing FP-GAme controller failed: %d",
		       ret);
		return ret;
	}

	return 0;
}

/**
 * @brief Handles an IOCTL call to the controller module.
 * @param inode Ignored.
 * @param file Ignored.
 * @param ioctl_num The ioctl command number.
 * @param ioctl_param Ignored.
 *
 * Fails if the command is not the controller read command.
 *
 * @return The current controller state on success, or -1 on failure.
 */
int con_ioctl(struct inode *inode, struct file *file,
              unsigned ioctl_num, unsigned long ioctl_param)
{
	(void)inode;
	(void)file;
	(void)ioctl_param;

	if (ioctl_num != IOCTL_CON_GET_STATE) { return -1; }

	/* TODO: Get controler state */
	return -1;
}

/**
 * @brief Cleans up the controller kernel module.
 * @return Void.
 */
void con_clean(void)
{
	int ret = unregister_chrdev(CON_MAJOR_NUM, CON_DEV_NAME);

	if (ret < 0) {
		printk(KERN_ALERT "Failed to clean FP-GAme controller: %d",
		       ret);
	}
}
