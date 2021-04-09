/**
 * @file apu.h
 * @author Andrew Spaulding
 * @brief Exposes the APU interface to the user.
 *
 * The APU interface consists of two functions. The first enables the APU
 * and registers a callback function to enq more buffer data whenever necessary.
 * The second disables the APU.
 *
 * Note that the first function will run the callback in a signal handler. The
 * user must manage the SIGINT signal if they need to disable the APU
 * callback, though this may result in silence for the user.
 *
 * Additionally, it is important to note that only one process may hold
 * access to the APU at a given time. The APU is released from this lock
 * on a call to disable, or when the program is closed.
 */

#ifndef _FP_GAME_APU_H_
#define _FP_GAME_APU_H_

#include <stdint.h>

/** @brief The maximum number of samples which may be given by a callback. */
#define APU_BUF_MAX 512

/**
 * @brief Enables the APU.
 *
 * Enables the APU, starting audio playback. The APU will be locked, and thus
 * only available to the current process.
 *
 * Whenever new samples are needed, the provided callback function will be
 * called. The callback must then fill the buf pointer with a buffer that
 * contains no more than APU_BUF_MAX samples. The size of the given buffer
 * must be placed inside of buf_size.
 *
 * Note that the samples provided by the callback function will not be played
 * immediately. The APU will attempt to maintain a "queued" buffer while it
 * plays the samples in its active buffer. Therefore, there will be up to a
 * 16ms delay between the callback supplying the samples and the samples
 * being played.
 *
 * Fails if the APU is already owned by another process.
 * It is illegal to provide this function with an invalid callback.
 *
 * @param callback The callback function to be called for more samples.
 * @return 0 on success, or -1 on error.
 */
int apu_enable(void (*callback)(int8_t **buf, int *buf_size));

/**
 * @brief Disables the APU.
 *
 * After the current buffer finishing playing, the APU will be silenced.
 *
 * Calling this function makes the APU available to other processing running
 * on the system.
 *
 * It is illegal to call this function if the APU is not currently enabled and
 * owned by the calling process.
 */
void apu_disable(void);

#endif /* _FP_GAME_APU_H_ */
