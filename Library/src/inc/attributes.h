/**
 * @file attributes.h
 * @brief Compiler attributes for gcc.
 * @author Andrew Spaulding
 * @bug No known bugs.
 */

#ifndef _GCC_ATTRIBUTES_H_
#define _GCC_ATTRIBUTES_H_

#ifdef __GNUC__

#define noreturn __attribute__ ((noreturn))
#define unused __attribute__ ((unused))

#else

#define noreturn
#define unused

#endif /* __GNUC__ */

#endif /* _GCC_ATTRIBUTES_H_ */
