/*
 * Test the communication between the FPGA and the HPS by reading the
 * controller register and printing the result.
 *
 * Author: Andrew Spaulding
 */

#include <stddef.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

#include <sys/mman.h>
#include <sys/stat.h>

#define CON_ADDR (0xFF200000U)
#define LW_REGS_RANGE (0x00200000U)

int main(void)
{
	/* First, we open memory as a file */
	int mem = open("/dev/mem", O_RDONLY);
	if (mem < 0) {
		fprintf(stderr, "Failed to open /dev/mem\n");
		return -1;
	}

	/* Next, we map the controllers MMIO */
	volatile unsigned *con_vaddr = mmap(NULL, LW_REGS_RANGE, PROT_READ,
	                                    MAP_SHARED, mem, CON_ADDR);
	if (con_vaddr == MAP_FAILED) {
		fprintf(stderr, "Failed to map controller address\n");
		close(mem);
		return -1;
	}

	printf("Controller state: %x\n", *con_vaddr);

	return 0;
}
