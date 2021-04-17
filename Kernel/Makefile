obj-m += con/con.o
obj-m += apu/apu.o
obj-m += ppu/ppu.o

all:
	make -C ../linux-socfpga/ M=$(PWD) ARCH=arm modules

clean:
	make -C ../linux-socfpga/ M=$(PWD) ARCH=arm clean
