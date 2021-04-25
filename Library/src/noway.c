/**
 * @file noway.c
 * @brief Implementation for error functions.
 * @author Andrew Spaulding
 */

#include <noway.h>

#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>

void _noway_helper(bool check, const char *file, int line,
                   const char *fn, const char *check_str)
{
	if ((file == NULL) || (line < 0) || (fn == NULL)
		           || (check_str == NULL))  {
		fprintf(stderr, "This can't be happening!\n"
		                "Bad args in noway()!\n");
		abort();
	}

	/* Phew! */
	if (!check) { return; }

	/* Oh dear. */
	fprintf(stderr, "No way! I can't believe this!\n"
	                "In %s on line %d in %s(), %s was true!\n"
			"Argh! He's not going to get away with this!\n",
			file, line, fn, check_str);
	abort();
}

void _nowaymsg_helper(bool check, const char *file, int line,
                      const char *fn, const char *check_str, const char *error_msg)
{
	if ((file == NULL) || (line < 0) || (fn == NULL)
		           || (check_str == NULL))  {
		fprintf(stderr, "This can't be happening!\n"
		                "Bad args in noway()!\n");
		abort();
	}

	/* Phew! */
	if (!check) { return; }

	/* Oh dear. */
	fprintf(stderr, "No way! I can't believe this!\n"
	                "In %s on line %d in %s(), %s was true!\n"
					"FP-GAme Error: %s\n",
			file, line, fn, check_str, error_msg);
	abort();
}

noreturn void _panic_helper(const char *err, const char *file, int line,
                            const char *fn) {
	if ((err == NULL) || (line < 0) || (file == NULL) || (fn == NULL)) {
		fprintf(stderr, "This can't be happening!\n"
		                "Bad args in panic()!\n");
		abort();
	}

	fprintf(stderr, "No way! I can't believe this!\n"
	                "In %s on line %d in %s(), panic was called!\n"
			"Reason: %s\n"
			"It's no use! Give up!\n",
			file, line, fn, err);
	abort();
}
