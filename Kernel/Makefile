obj-m += con/con.o
obj-m += apu/apu.o

all:
	make -C ../linux-socfpga/ M=$(PWD) ARCH=arm modules

clean:
	make -C ../linux-socfpga/ M=$(PWD) ARCH=arm clean
