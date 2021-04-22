/**
 * @file apu.c
 * @author Andrew Spaulding
 * @brief Kernel module for the FP-GAme audio processing unit.
 *
 * This file implements the APU kernel driver.
 *
 * The apu expects to receive the base address of a sample buffer that is
 * located in ddr3 memory. Once given to the APU, this buffer must not change
 * while it is in use by the APU. The APU uses interrupts to communicate when
 * a buffer has been fully consumed. We use these interrupts to inform
 * a user mode process, which currently owns the APU, that we need more
 * samples.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/io-mapping.h>
#include <linux/atomic.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/sched.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/dma-mapping.h>
#include <asm-generic/io.h>
#include <asm/io.h>
#include <asm/uaccess.h>
#include <linux/device.h>
#include <linux/kdev_t.h>

#include <linux/fp-game/drv_apu.h>

/** @brief The address of the apu's memory mapped I/O. */
//@{
#define APU_MMIO_BASE 0xFF200010
#define APU_MMIO_SIZE 0x20
#define APU_CONFIG_OFFSET 0x00
#define APU_BUF_OFFSET 0x10
//@}

/** @brief The name of the apu device. */
#define APU_DEV_NAME "fp_game_apu"

/** @brief Flags and masks for using the apu control register. */
//@{
#define APU_IRQ_ACK 0x01
#define APU_IRQ_REQ 0x02
#define APU_ENABLE 0x04
//@}

/** @brief The size of each apu sample buffer. */
#define APU_BUF_SIZE (sizeof(unsigned char) * 512)

/* Module Functions */
static int apu_probe(struct platform_device *pdev);
static irqreturn_t apu_irq(int irq, void *dev_id);
static int apu_open(struct inode *inode, struct file *file);
static long apu_ioctl(struct file *file, unsigned ioctl_num,
                      unsigned long ioctl_param);
static ssize_t apu_write(struct file *file, const char __user *buf,
                         size_t len, loff_t *offset);
static int apu_release(struct inode *inode, struct file *file);
static int apu_remove(struct platform_device *pdev);

/* Helper Functions */
static void mmio_write(unsigned addr, unsigned val);
static void send_user_interrupt(pid_t pid, int code);

/** @brief The I/O mapping region for the apu driver. */
static struct io_mapping *apu_io;

/** @brief The device structure for the apu. */
static struct device *apu_dev;

/** @brief The lock used to protect the APU from multiple processes. */
static atomic_t apu_lock;

/** @brief Device Class for this driver */
struct class *cl;

/**
 * @brief The structure type used to manage apu sample sending/receiving.
 *
 * On initialization, the driver requests twice the apu buffer size
 * of dma-able memory. This memory is assigned to our double buffered
 * sample buffer, buf. dma_addr is also given the base physical address
 * that the apu should use to access samples by that request.
 *
 * active_buf denotes the buffer currently being used by the apu to play
 * samples (which should not be written to).
 *
 * sample_req and pid are used to coordinate communication with the user
 * mode part of the driver. The user mode portion must register its pid
 * with the driver after making a successful call to open on our device file.
 * Once that is done, interrupts will be enabled. The interrupt handler
 * will set sample_req to 1, which is exchanged to 0 during the write call
 * the user mode driver makes to send us new samples. This prevents us from
 * receiving multiple new sample buffers per sample frame.
 */
struct apu_sample {
	// Driver instance specific info.
	unsigned char *buf[2];
	unsigned active_buf;
	dma_addr_t dma_addr;

	// User instance specific info.
	atomic_t req;
	pid_t pid;
} sample;

/**
 * @brief Interrupt table structure thing.
 *
 * Defines the device our kernel module is compatible with, which is used
 * to get linux to call probe on us so we can register our interrupt handler.
 */
static const struct of_device_id apu_int_table[] = {
	{.compatible = "altr,socfpga-fpgameapu"},
	{},
};

/**
 * @brief Platform driver structure.
 *
 * Sets up our kernel module as the platform driver for the APU.
 */
static struct platform_driver apu_platform = {
	.driver = {
		.name = APU_DEV_NAME,
		.owner = THIS_MODULE,
		.of_match_table = of_match_ptr(apu_int_table),
	},
	.probe = apu_probe,
	.remove = apu_remove,
};


/**
 * @brief File operations structure.
 *
 * This structure is used to inform the linux kernel which system calls our
 * device driver implements.
 */
static struct file_operations fops = {
	.open = apu_open,
	.unlocked_ioctl = apu_ioctl,
	.write = apu_write,
	.release = apu_release,
};

/**
 * @brief Initializes the apu kernel module.
 * @param pdev The platform device for the apu.
 * @return 0 on success, or a negative integer on failure.
 */
static int apu_probe(struct platform_device *pdev)
{
	int ret;
	int irq;
    dev_t dev;

	/* Register our driver with the kernel. */
	ret = register_chrdev(APU_MAJOR_NUM, APU_DEV_NAME, &fops);

	if (ret < 0) {
		printk(KERN_ALERT "Initializing FP-GAme apu module failed: %d",
		       ret);
		return ret;
	}

	/* Map the apu I/O. */
	apu_io = io_mapping_create_wc(APU_MMIO_BASE, APU_MMIO_SIZE);

	/* Allocate sample buffers */
	apu_dev = &(pdev->dev);
	sample.buf[0] = dma_alloc_coherent(apu_dev, APU_BUF_SIZE << 1,
	                                   &sample.dma_addr, GFP_KERNEL);
	sample.buf[1] = &(sample.buf[0][APU_BUF_SIZE]);
	if (sample.buf[0] == NULL) {
		printk(KERN_ALERT "FP-GAme apu failed to alloc sample buffers");
		return -1;
	}

	irq = platform_get_irq(pdev, 0);
	ret = request_irq(irq, apu_irq, 0, APU_DEV_NAME, apu_irq);

	if (ret < 0) {
		printk(KERN_ALERT "FP-GAme apu failed to register irq");
	}

    // Create the device in /dev
    cl = class_create(THIS_MODULE, APU_DEV_NAME);
    dev = MKDEV(APU_MAJOR_NUM, 0);
    device_create(cl, NULL, dev, NULL, APU_DEV_NAME);

	return ret;
}

/**
 * @brief Handles an apu irq.
 *
 * When an apu irq is received, a request for more samples will be sent
 * to the user (if a user has been specified) and the active apu buffer
 * will be switched. The next write to the apu module will fill the buffer
 * that this interrupt signaled the emptying of.
 *
 * @param irq Ignored.
 * @param dev_id Ignored.
 * @return IRQ_HANDLED, signaling the successful handling of the irq.
 */
static irqreturn_t apu_irq(int irq, void *dev_id)
{
	/* Acknowledge the interrupt, dropping the IRQ line. */
	mmio_write(APU_CONFIG_OFFSET, APU_IRQ_ACK | APU_ENABLE);

	/* Signal the user process that we need more samples. */
	atomic_set(&sample.req, 1);
	if (sample.pid) { send_user_interrupt(sample.pid, APU_MAJOR_NUM); }

	return IRQ_HANDLED;
}

/**
 * @brief Attempts to open the APU module file.
 *
 * If the APU has already been opened by another process, fails.
 *
 * @param inode Ignored.
 * @param file Ignored.
 * @return 0 on success, -1 on error.
 */
static int apu_open(struct inode *inode, struct file *file)
{
	/* Acquire the apu. */
	return (atomic_xchg(&apu_lock, 1) == 0) ? 0 : -EBUSY;
}

/**
 * @brief Handles an IOCTL call to the apu module.
 *
 * Fails if the command is not the set callback pid command.
 *
 * @param file Ignored.
 * @param ioctl_num The ioctl command number.
 * @param ioctl_param The PID to send the callback signal to.
 * @return 0 on success, or -1 on failure.
 */
static long apu_ioctl(struct file *file, unsigned ioctl_num,
                      unsigned long ioctl_param)
{
	if (ioctl_num != IOCTL_APU_SET_CALLBACK_PID) { return -EINVAL; }

	sample.pid = ioctl_param;
	mmio_write(APU_CONFIG_OFFSET, APU_ENABLE | APU_IRQ_REQ);
	return 0;
}

/**
 * @brief Reads user samples into the next sample buffer.
 *
 * This function may only be called once per sample request, and may only
 * be called from one process/thread at a time.
 *
 * Fails if the resulting size is larger than the APU sample buffer size,
 * or if the user supplied sample buffer is invalid.
 *
 * @param file Ignored.
 * @param buf The user supplied sample buffer.
 * @param elt_size The size of the given buffer.
 * @param len Ignored.
 * @return 0 on success, or a negative integer on error.
 */
static ssize_t apu_write(struct file *file, const char __user *buf,
                         size_t len, loff_t *offset)
{
	static atomic_t write_lock;

	/* Verify length arguments */
	if (len > APU_BUF_SIZE) {
		return -EINVAL;
	}

	/* Disallow concurrent writes to the sample buffer. */
	if (atomic_xchg(&write_lock, 1) == 1) { return -EBUSY; }

	/* Ensure that the buffer is only written to once per sample request. */
	if (atomic_xchg(&sample.req, 0) != 1) {
		atomic_set(&write_lock, 0);
		return -EBUSY;
	}

	/* Copy from user memory. Clear unspecified samples. */
	if (copy_from_user(sample.buf[!sample.active_buf], buf, len) != 0) {
		memset(sample.buf[!sample.active_buf], 0, APU_BUF_SIZE);
		atomic_set(&write_lock, 0);
		return -EFAULT;
	} else {
		memset(&sample.buf[!sample.active_buf][len],
		       0, APU_BUF_SIZE - len);
	}

	/* Ensure our changes are seen */
	wmb();

	/* Send the new buffer. */
	mmio_write(APU_BUF_OFFSET, sample.dma_addr
	           + ((!sample.active_buf) ? APU_BUF_SIZE : 0));
	sample.active_buf = !sample.active_buf;

	atomic_set(&write_lock, 0);

	/* Enable IRQs now that we've released the lock. */
	mmio_write(APU_CONFIG_OFFSET, APU_ENABLE | APU_IRQ_REQ);
	return 0;
}

/**
 * @brief Closes the apu device file.
 *
 * Calling this function releases the apu lock, allowing other processes
 * to use the apu.
 *
 * @return 0 on success, -1 on error.
 */
static int apu_release(struct inode *inode, struct file *file)
{
	/* Reset user specific info. */
	sample.pid = 0;
	atomic_set(&sample.req, 0);

	/* Mute output and disable apu IRQs. */
	mmio_write(APU_CONFIG_OFFSET, 0);

	/* Release the apu. */
	if (atomic_xchg(&apu_lock, 0) == 0) {
		printk(KERN_ALERT "Close called on apu when it wasn't open!");
	}

	return 0;
}

/**
 * @brief Cleans up the apu kernel module.
 * @param pdev The platform device of the apu.
 * @return 0.
 */
static int apu_remove(struct platform_device *pdev)
{
    dev_t dev;
    dev = MKDEV(APU_MAJOR_NUM, 0);
    device_destroy(cl, dev);
    class_destroy(cl);

	unregister_chrdev(APU_MAJOR_NUM, APU_DEV_NAME);
	io_mapping_free(apu_io);
	dma_free_coherent(apu_dev, APU_BUF_SIZE << 1,
	                  sample.buf[0], sample.dma_addr);

	mmio_write(APU_CONFIG_OFFSET, 0);
	free_irq(platform_get_irq(pdev, 0), NULL);

	return 0;
}

/**
 * @brief Writes a value to mmio.
 * @param offset The offset from the mmio base to write to.
 * @param val The value to be written.
 * @return Void.
 */
static void mmio_write(unsigned offset, unsigned val)
{
	void *addr;

	/* WARNING: This function disables preemption! */
	addr = io_mapping_map_atomic_wc(apu_io, offset);
	writel(val, addr);
	io_mapping_unmap_atomic(addr);
}

/**
 * @brief Sends an interrupt to a user space process via sigint.
 * @param pid The pid to send the signal to.
 * @param code The interrupt code to give the user in their handler.
 * @return Void.
 */
static void send_user_interrupt(pid_t pid, int code)
{
	struct task_struct *task;

	/* Construct the siginfo to be sent */
	struct kernel_siginfo info = {
		.si_signo = APU_CALLBACK_SIG,
		.si_code = SI_KERNEL,
		.si_int = 0,
	};

	/* Find the task associated with our current PID */
	rcu_read_lock();
	task = pid_task(find_pid_ns(pid, &init_pid_ns), PIDTYPE_PID);
	rcu_read_unlock();

	/* Bad task, probably the users fault. */
	if (task == NULL) {
		printk(KERN_ALERT "Could not send APU sig to invalid task!");
		return;
	}

	/* Send the signal */
	if (send_sig_info(APU_CALLBACK_SIG, &info, task) < 0) {
		printk(KERN_ALERT "Failed to dispatch APU sig!");
	}
}

module_platform_driver(apu_platform);

MODULE_AUTHOR("Andrew Spaulding");
MODULE_DESCRIPTION("THEIR SCREAMS ARE MUSIC TO MY AUDIO RECEPTORS!!!");
MODULE_LICENSE("GPL"); /* I wonder if this is legally binding \_(ツ)_/ */
