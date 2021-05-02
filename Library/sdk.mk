SDK = $(FPGAME_TC)
CC_INC = $(SDK)/lib/gcc/arm-none-linux-gnueabihf/10.2.1/include
LIBC_INC = $(SDK)/arm-none-linux-gnueabihf/libc/usr/include
LIBCXX_INC = $(SDK)/arm-none-linux-gnueabihf/include/c++/10.2.1
INC = $(CC_INC) $(LIBC_INC) $(LIBCXX_INC)
