/**
 * @file noway.h
 * @brief Provides a function for making error checking assertions.
 * @author Andrew Spaulding
 */

#ifndef _NO_WAY_H_
#define _NO_WAY_H_

#include <stdbool.h>
#include <attributes.h>

#define noway(err) _noway_helper(err, __FILE__, __LINE__, __func__, #err)
#define nowaymsg(err, msg) _nowaymsg_helper(err, __FILE__, __LINE__, __func__, #err, msg)
#define panic(err) _panic_helper(err, __FILE__, __LINE__, __func__)

/* For internal use only. */
void _noway_helper(bool assert, const char *file, int line,
                   const char *fn, const char *assert_str);

void _nowaymsg_helper(bool assert, const char *file, int line,
                      const char *fn, const char *assert_str, const char *error_msg);

noreturn void _panic_helper(const char *err, const char *file,
                            int line, const char *fn);

#endif /* _NO_WAY_H_ */
