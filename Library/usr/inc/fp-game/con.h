/**
 * @file con.h
 * @author Andrew Spaulding
 * @brief Exposes the controller interface to the user
 *
 * The controller interface consists of a single function, which can be
 * called to get the current controller state.
 *
 * The controller state is returned as an integer, with each button represented
 * in a single bit. Masks are provided to access the bits which represent each
 * button. Note that the signal received from the controller is active low:
 * a 1 in the bit for a button means the button is *released*.
 *
 * In addition to the masks provided, macros are provided to check if a button
 * is currently pressed or released given a button mask and a state.
 */

#ifndef _FP_GAME_CON_H_
#define _FP_GAME_CON_H_

/** @brief These masks define the bit in which each button state is stored. */
/**@{*/
#define CON_BUT_B (1 << 15)
#define CON_BUT_Y (1 << 14)
#define CON_BUT_SELECT (1 << 13)
#define CON_BUT_START (1 << 12)
#define CON_BUT_UP (1 << 11)
#define CON_BUT_DOWN (1 << 10)
#define CON_BUT_LEFT (1 << 9)
#define CON_BUT_RIGHT (1 << 8)
#define CON_BUT_A (1 << 7)
#define CON_BUT_X (1 << 6)
#define CON_BUT_L (1 << 5)
#define CON_BUT_R (1 << 4)
/**@}*/

/**
 * @brief Returns true if the given button is pressed in the given state.
 * @param state The current controller state.
 * @param but The button mask to be checked against.
 * @return true if the button is pressed, false otherwise.
 */
#define CON_IS_PRESSED(state, but) (!((state) & (but)))

/**
 * @brief Returns true if the given button is released in the given state.
 * @param state The current controller state.
 * @param but The button mask to be checked against.
 * @return true if the button is released, false otherwise.
 */
#define CON_IS_RELEASED(state, but) (!!((state) & (but)))

/**
 * @brief Gets the current controller state.
 * @return The current controller state on success, or a
 *         negative integer on failure.
 */
int get_con_state(void);

#endif /* _FP_GAME_CON_H_ */
