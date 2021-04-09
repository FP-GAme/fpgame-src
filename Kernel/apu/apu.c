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
#include <asm-generic/io.h>
#include <asm/io.h>
#include <asm/uaccess.h>

#include <linux/fp-game/drv_apu.h>

/** @brief The address of the apu's memory mapped I/O. */
//@{
#define APU_MMIO_BASE 0xFF200010
#define APU_MMIO_SIZE 0x20
#define APU_CONFIG_OFFSET 0x00
#define APU_BUF_OFFSET 0x10
//@}

/** @brief The IRQ number the apu uses. */
#define APU_IRQ_ID /* FIXME */

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

/** @brief The I/O mapping region for the apu driver. */
static struct io_mapping *apu_io;

/** @brief The lock used to protect the APU from multiple processes. */
static atomic_t apu_lock;

/** @brief The pid which should be sent the SIGINT for callback. */
static pid_t callback_pid;

/** @brief The buffers which will hold the active and pending samples. */
static unsigned char *sample_buf[2];

/** @brief Indicates which buffer the user should write to. */
static unsigned active_buf;

/* Module Functions */
int apu_init(void);
int apu_open(struct inode *inode, struct file *file);
long apu_ioctl(struct file *file, unsigned ioctl_num,
               unsigned long ioctl_param);
ssize_t apu_write(struct file *file, const char __user *buf,
                  size_t elt_size, loff_t len);
int apu_release(struct inode *inode, struct file *file);
void apu_clean(void);

/* Helper Functions */
static void mmio_write(unsigned addr, unsigned val);
static void send_user_interrupt(pid_t pid, int code);

/**
 * @brief File operations structure.
 *
 * This structure is used to inform the linux kernel which system calls our
 * device driver implements.
 */
struct file_operations fops = {
	.open = apu_open,
	.unlocked_ioctl = apu_ioctl,
	.write = apu_write,
	.release = apu_release
};

/**
 * @brief Initializes the apu kernel module.
 * @return 0 on success, and a negative integer on failure.
 */
int apu_init(void)
{
	/* Register our driver with the kernel. */
	int ret = register_chrdev(APU_MAJOR_NUM, APU_DEV_NAME, &fops);

	if (ret < 0) {
		printk(KERN_ALERT "Initializing FP-GAme apu module failed: %d",
		       ret);
		return ret;
	}

	/* Map the apu I/O. */
	apu_io = io_mapping_create_wc(APU_MMIO_BASE, APU_MMIO_SIZE);

	/* Allocate sample buffers */
	sample_buf[0] = kzalloc(APU_BUF_SIZE << 1, GFP_KERNEL);
	sample_buf[1] = &sample_buf[0][APU_BUF_SIZE];
	if (sample_buf[0] == NULL) {
		printk(KERN_ALERT "FP-GAme apu failed to alloc sample buffers");
		return -1;
	}

	/* Setup interrupt handler */
	if (request_irq(APU_IRQ_ID, apu_irq, 0, APU_DEV_NAME, apu_irq) < 0)
		printk(KERN_ALERT "FP-GAme apu failed to register irq");
		kfree(sample_buf[0]);
		return -1;
	}

	return 0;
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
 * @param regs Ignored.
 * @return IRQ_HANDLED, signaling the successful handling of the irq.
 */
irqreturn_t apu_irq(int irq, void *dev_id, struct pt_regs *regs)
{
	(void)irq;
	(void)dev_id;
	(void)regs;

	/* Switch the active buffer */
	active_buf = !active_buf;

	/* Acknowledge the interrupt, dropping the IRQ line. */
	mmio_write(APU_CONFIG_OFFSET, APU_IRQ_ACK | APU_ENABLE);

	/* Signal the user process that we need more samples. */
	if (pid) { send_user_interrupt(callback_pid, APU_MAJOR_NUM); }
}

/**
 * @brief Attempts to open the APU module file.
 *
 * If the APU has already been opened by another process, fails.
 *
 * @return 0 on success, -1 on error.
 */
int apu_open(struct inode *inode, struct file *file)
{
	/* Acquire the apu. */
	return (atomic_xchg(&apu_lock, 1) == 0) ? 0 : -EBUSY;
}

/**
 * @brief Handles an IOCTL call to the apu module.
 * @param file Ignored.
 * @param ioctl_num The ioctl command number.
 * @param ioctl_param The PID to send the callback signal to.
 *
 * Fails if the command is not the set callback pid command.
 *
 * @return 0 on success, or -1 on failure.
 */
long apu_ioctl(struct file *file, unsigned ioctl_num,
               unsigned long ioctl_param)
{
	(void)file;

	if (ioctl_num != IOCTL_APU_SET_CALLBACK_PID) { return -EINVAL; }

	callback_pid = ioctl_param;
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
 * @param elt_size The size of each element to write.
 * @param len The number of elements to write.
 * @return 0 on success, or a negative integer on error.
 */
ssize_t apu_write(struct file *file, const char __user *buf,
                  size_t elt_size, loff_t len)
{
	/* Verify length arguments */
	int to_copy = elt_size * len;
	if ((elt_size >= APU_BUF_SIZE) || (len < 0)
			|| (len > APU_BUF_SIZE) || (to_copy > APU_BUF_SIZE)) {
		return -EINVAL;
	}

	/* Disallow concurrent writes to the sample buffer. */
	static atomic_t write_lock = 0;
	if (atomic_xchg(&write_lock, 1) == 1) { return -EBUSY; }

	/* Ensure that the buffer is only written to once per sample request. */
	static int passive_buf = 0;
	if (passive_buf == active_buf) {
		atomic_write(&write_lock, 0);
		return -EBUSY;
	}

	// Copy from user memory. Clear unspecified samples.
	if (copy_from_user(sample_buf[passive_buf], buf, to_copy) != 0) {
		memset(sample_buf[passive_buf], 0, APU_BUF_SIZE);
		atomic_write(&write_lock, 0);
		return -EFAULT;
	} else {
		memset(&sample_buf[passive_buf][to_copy], 0,
			APU_BUF_SIZE - to_copy);
	}

	/* Send the new buffer and enable audio output and irqs */
	mmio_write(APU_BUF_OFFSET, virt_to_phys(sample_buf[passive_buf]));
	mmio_write(APU_CONFIG_OFFSET, APU_ENABLE | APU_IRQ_REQ);

	/* Flip passive buf to disallow new samples until the next irq. */
	passive_buf = !passive_buf;

	atomic_write(&write_lock, 0);
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
int apu_release(struct inode *inode, struct file *file)
{
	/* Release the apu. */
	if (atomic_xchg(&apu_lock, 0) == 0) { return -EIO; }

	/* Mute output and disable apu IRQs. */
	mmio_write(APU_CONFIG_OFFSET, 0);

	return 0;
}

/**
 * @brief Cleans up the apu kernel module.
 * @return Void.
 */
void apu_clean(void)
{
	mmio_write(APU_CONFIG_OFFSET, 0);

	unregister_chrdev(APU_MAJOR_NUM, APU_DEV_NAME);
	io_mapping_free(apu_io);
	free_irq(APU_IRQ_ID, apu_irq);
	kfree(sample_buf[0]);
}

/**
 * @brief Writes a value to mmio.
 * @param offset The offset from the mmio base to write to.
 * @param val The value to be written.
 * @return Void.
 */
static void mmio_write(unsigned offset, unsigned val)
{
	void *addr = io_mapping_map_local_wc(offset, 0, sizeof(unsigned));
	writel(val, addr);
	io_mapping_unmap_local(addr);
}

/**
 * @brief Sends an interrupt to a user space process via sigint.
 * @param pid The pid to send the signal to.
 * @param code The interrupt code to give the user in their handler.
 * @return Void.
 */
static void send_user_interrupt(pid_t pid, int code)
{
	/* Construct the siginfo to be sent */
	struct siginfo info = {
		.si_signo = APU_CALLBACK_SIG,
		.si_code = SI_KERNEL,
		.si_int = 0,
	};

	/* Find the task associated with our current PID */
	rcu_read_lock();
	struct task_struct *task = pid_task(find_pid_ns(pid, &init_pid_ns),
					    PIDTYPE_PID);
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

module_init(apu_init);
module_exit(apu_clean);

MODULE_AUTHOR("Andrew Spaulding");
MODULE_DESCRIPTION("THEIR SCREAMS ARE MUSIC TO MY AUDIO RECEPTORS!!!");
MODULE_LICENSE("GPL"); /* I wonder if this is legally binding \_(ツ)_/ */
