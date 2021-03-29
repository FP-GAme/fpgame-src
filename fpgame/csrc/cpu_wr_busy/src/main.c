/*
 * Test the communication between the FPGA and the HPS by reading the
 * controller register and printing the result.
 *
 * Author: Andrew Spaulding
 */

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>

#include <sys/mman.h>
#include <sys/stat.h>

#include "../inc/fpgame_hps.h"

// === TODO: MAKE VRAM HEADERS ===
#define LW_H2F_MMIO_BASE  (0xFF200000U)
#define LW_H2F_MMIO_RANGE (0x00200000U)

int main(int argc, char *argv[])
{
    /* Arguments List:
     *
     * 1: Set cpu_wr busy ON/OFF (1, or 0)
     */

    if (argc != 2)
    {
        fprintf(stderr, "Missing Argument: Give 1 to set cpu_wr_busy=1, 0 to set cpu_wr_busy=0\n");
        return -1;
    }

    /* First, we open memory as a file */
    int mem = open("/dev/mem", O_RDWR | O_SYNC);
    if (mem < 0) {
        perror("Failed to open /dev/mem");
        return -1;
    }

    /* Next, we map the controllers MMIO */
    volatile uint8_t *lw_h2f_vaddr = mmap(NULL, LW_H2F_MMIO_RANGE, PROT_WRITE, MAP_SHARED, mem,
                                          LW_H2F_MMIO_BASE);
    if (lw_h2f_vaddr == MAP_FAILED) {
        perror("Failed to map H2F_MMIO address");
        close(mem);
        return -1;
    }

    volatile uint8_t *wr_addr = lw_h2f_vaddr + CPU_WR_BUSY_PIO_BASE;

    uint8_t wr_data = atoi(argv[1]);

    printf("Writing %d to address %p\n", wr_data, wr_addr);

    *wr_addr = wr_data & 1;

    printf("Written.\n");

    return 0;
}