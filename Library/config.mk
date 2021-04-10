# The name of the application to be built.
TARGET = libfpgame.a

# The architecture being compiled for.
ARCH = arm

# The objects to be compiled from .c and .S source files
COBJ = $(patsubst %.c,%.o,$(shell find ./src -name '*.c'))
ASMOBJ =

# The folders to include headers from, reletive to make
INC = src/inc usr/inc kern/inc

# The directory to output the library to.
OUTDIR = usr

# The compiler to be used and its C flags.
AR = ar
CC = arm-none-linux-gnueabihf-gcc
CFLAGS = -std=gnu99
