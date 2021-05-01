/**
 * @file apu.c
 * @author Andrew Spaulding
 * @brief APU interface implementation.
 */

#include <fp-game/apu.h>

#include <sys/ioctl.h>
#include <fp-game/drv_apu.h>
#include <fcntl.h>
#include <unistd.h>

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <signal.h>

#include <noway.h>

/** @brief The file descriptor for the apu device file. */
static int apu_fd = -1;

/** @brief The callback function given by the user when enabling the apu. */
static void (*callback_fn)(const int8_t **buf, int *buf_size) = NULL;

/* Helper Functions */
static void apu_sig_handler(int sig);

int apu_enable(void (*callback)(const int8_t **buf, int *buf_size))
{
	noway(callback == NULL);
	noway(apu_fd != -1);

	/* Open the apu device file */
	apu_fd = open(APU_DEV_FILE, O_WRONLY);
	if (apu_fd < 0) { return -1;}

	/* Register our signal handler for APU interrupts. */
	callback_fn = callback;
	struct sigaction sig = {
		.sa_handler = apu_sig_handler,
		.sa_flags = SA_RESTART,
	};
	sigemptyset(&sig.sa_mask);
	noway(sigaction(APU_CALLBACK_SIG, &sig, NULL) < 0);

	/* Send the apu our pid so that it may send us interrupts. */
	noway(ioctl(apu_fd, IOCTL_APU_SET_CALLBACK_PID, getpid()) < 0);

	return 0;
}

void apu_disable(void)
{
	noway(apu_fd == -1);

	close(apu_fd);
	sigaction(APU_CALLBACK_SIG, NULL, NULL);

	apu_fd = -1;
	callback_fn = NULL;
}

void apu_callback_enable(void)
{
	sigset_t mask;
	sigemptyset(&mask);
	sigaddset(&mask, APU_CALLBACK_SIG);
	sigprocmask(SIG_UNBLOCK, &mask, NULL);
}

void apu_callback_disable(void)
{
	sigset_t mask;
	sigemptyset(&mask);
	sigaddset(&mask, APU_CALLBACK_SIG);
	sigprocmask(SIG_BLOCK, &mask, NULL);
}

/**
 * @brief Handles an apu interrupt by calling the users callback function.
 * @param sig Ignored.
 */
static void apu_sig_handler(int sig)
{
	(void)sig;
	noway(callback_fn == NULL);

	/* Get new samples from the user. */
	const int8_t *buf;
	int len;
	callback_fn(&buf, &len);

	/* Send the new samples to the apu. */
	if (write(apu_fd, buf, len)) {
		printf("Write failed!\n");
		perror("FUCK");
	}
}
