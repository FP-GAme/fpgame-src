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
#include <linux/io-mapping.h>
#include <asm-generic/io.h>
#include <linux/device.h>
#include <linux/kdev_t.h>

#include <linux/fp-game/drv_con.h>

/** @brief The address of the controllers memory mapped i/o */
#define CON_MMIO_ADDR 0xFF200000

/** @brief The name of the CON device. */
#define CON_DEV_NAME "fp_game_con"

/** @brief The I/O mapping region for the controller driver. */
static struct io_mapping *con_io;

/* Functions */
int con_init(void);
long con_ioctl(struct file *file, unsigned ioctl_num,
               unsigned long ioctl_param);
void con_clean(void);

/**
 * @brief File operations structure.
 *
 * This structure is used to inform the linux kernel which system calls our
 * device driver implements.
 */
struct file_operations fops = {
	.unlocked_ioctl = con_ioctl
};

/** @brief Device Class for this driver */
struct class *cl;

/**
 * @brief Initializes the controller kernel module.
 * @return 0 on success, and a negative integer on failure.
 */
int con_init(void)
{
    dev_t dev;

	/* Register our driver with the kernel. */
	int ret = register_chrdev(CON_MAJOR_NUM, CON_DEV_NAME, &fops);

	if (ret < 0) {
		printk(KERN_ALERT "Initializing FP-GAme controller failed: %d",
		       ret);
		return ret;
	}

	/* Map the controller I/O. */
	con_io = io_mapping_create_wc(CON_MMIO_ADDR, sizeof(int));

    // Create the device in /dev
    cl = class_create(THIS_MODULE, CON_DEV_NAME);
    dev = MKDEV(CON_MAJOR_NUM, 0);
    device_create(cl, NULL, dev, NULL, CON_DEV_NAME);

	return 0;
}

/**
 * @brief Handles an IOCTL call to the controller module.
 * @param file Ignored.
 * @param ioctl_num The ioctl command number.
 * @param ioctl_param Ignored.
 *
 * Fails if the command is not the controller read command.
 *
 * @return The current controller state on success, or -1 on failure.
 */
long con_ioctl(struct file *file, unsigned ioctl_num,
               unsigned long ioctl_param)
{
	void *con_addr;
	int state;
	(void)file;
	(void)ioctl_param;

	if (ioctl_num != IOCTL_CON_GET_STATE) { return -1; }

	/*
	 * Map our address. This holds a lock, so we must unmap it after
	 * reading the controller state.
	 */
	con_addr = io_mapping_map_atomic_wc(con_io, 0);
	state = readl(con_addr);
	io_mapping_unmap_atomic(con_addr);

	return state;
}

/**
 * @brief Cleans up the controller kernel module.
 * @return Void.
 */
void con_clean(void)
{
    dev_t dev;
    dev = MKDEV(CON_MAJOR_NUM, 0);
    device_destroy(cl, dev);
    class_destroy(cl);

	unregister_chrdev(CON_MAJOR_NUM, CON_DEV_FILE);
	io_mapping_free(con_io);
}

module_init(con_init);
module_exit(con_clean);

MODULE_AUTHOR("Andrew Spaulding");
MODULE_DESCRIPTION("The nightmares, Snake? They never go away.");
MODULE_LICENSE("Dual MIT/GPL"); /* I wonder if this is legally binding \_(ツ)_/ */