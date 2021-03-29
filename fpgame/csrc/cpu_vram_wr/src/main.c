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
#include <stdbool.h>

#include <sys/mman.h>
#include <sys/stat.h>

#include "../inc/fpgame_hps.h"

// === TODO: MAKE VRAM HEADERS ===
#define H2F_MMIO_BASE  (0xC0000000U)
#define H2F_MMIO_RANGE (0x3C000000U)

// All numbers are in terms of Bytes and are relative to H2F_MMIO_BASE + H2F_VRAM_INTERFACE_0_BASE
#define TILE_OFFSET    (0x0000U)
#define TILE_RANGE     (16384u)
//#define TILE_END       (0x3FFF)

#define PATTERN_OFFSET (0x4000U)
#define PATTERN_RANGE  (32768u)
//#define PATTERN_END    (0xBFFF)

#define PALETTE_OFFSET (0xC000U)
#define PALETTE_RANGE  (4096u)
//#define PALETTE_END    (0xCFFF)

#define SPRITE_OFFSET  (0xD000U)
#define SPRITE_RANGE   (320U)
//#define SPRITE_END     (0xD13F)

//#define VRAM_RANGE     (TILE_RANGE + PATTERN_RANGE + PALETTE_RANGE + SPRITE_RANGE)
// === TODO: MAKE VRAM HEADERS ===

// This function will return an offset from the base of MMIO-accessible VRAM given the segment id
//   and rel addr
// The in_bounds bool will be false if an error occurs.
uint32_t calc_vram_offset (uint32_t vram_seg_id, uint32_t rel_addr, bool *in_bounds)
{

    if (vram_seg_id == 0 && rel_addr < TILE_RANGE)
    {
        *in_bounds = true;
        return TILE_OFFSET + rel_addr;
    }
    else if (vram_seg_id == 1 && rel_addr < PATTERN_RANGE)
    {
        *in_bounds = true;
        return PATTERN_OFFSET + rel_addr;
    }
    else if (vram_seg_id == 2 && rel_addr < PALETTE_RANGE)
    {
        *in_bounds = true;
        return PALETTE_OFFSET + rel_addr;
    }
    else if (vram_seg_id == 3 && rel_addr < SPRITE_RANGE)
    {
        *in_bounds = true;
        return SPRITE_OFFSET + rel_addr;
    }

    *in_bounds = false;
    return 0;
}

int main(int argc, char *argv[])
{
    /* Arguments List:
     *
     * 1: VRAM Segment ID (0, 1, 2, 3) (Decimal)
     * -> 0 Corresponds to Tile RAM,
     * -> 1 Corresponds to Pattern RAM,
     * -> 2 Corresponds to Palette RAM,
     * -> 3 Corresponds to Sprite RAM

     * 2: Relative Address (Decimal)

     * 3: Write Data Size (8, 16, 32, 64) (Decimal)
     * -> 0 Corresponds to uint8_t,
     * -> 1 Corresponds to uint16_t,
     * -> 2 Corresponds to uint32_t,
     * -> 3 Corresponds to uint64_t

     * 4: Write Data (Hex).
     */

    char vram_seg_id_str[4][8] = {
        "Tile",
        "Pattern",
        "Palette",
        "Sprite"
    };

    if (argc != 5)
    {
        fprintf(stderr, "Must supply VRAM Segment ID (0, 1, 2, 3), Relative Address (Hex)"
                        "Write Data Size (8, 16, 32, 64), and Write Data (Hex)\n");
        return -1;
    }

    uint32_t vram_seg_id = strtoul(argv[1], NULL, 10);
    if (vram_seg_id > 3)
    {
        fprintf(stderr, "VRAM Segment ID out of range. Please specify one of (0, 1, 2, 3)\n");
        return -1;
    }
    printf("Selected VRAM Segment: %s RAM\n", vram_seg_id_str[vram_seg_id]);

    uint32_t rel_addr = strtoul(argv[2], NULL, 16);

    bool in_bounds = false;
    uint32_t vram_offset = calc_vram_offset(vram_seg_id, rel_addr, &in_bounds);
    if (in_bounds == false) {
        fprintf(stderr, "Relative Address %X outside of %s RAM range\n", rel_addr,
                vram_seg_id_str[vram_seg_id]);
        return -1;
    }

    printf("Relative Address: %X\n", vram_offset);

    /* First, we open memory as a file */
    int mem = open("/dev/mem", O_RDWR | O_SYNC);
    if (mem < 0) {
        perror("Failed to open /dev/mem");
        return -1;
    }

    printf("Opened /dev/mem successful\n");

    /* Next, we map the controllers MMIO */
    volatile uint8_t *h2f_vaddr = mmap(NULL, H2F_MMIO_RANGE, PROT_WRITE,
                                        MAP_SHARED, mem, H2F_MMIO_BASE);
    if (h2f_vaddr == MAP_FAILED) {
        perror("Failed to map H2F_MMIO address");
        close(mem);
        return -1;
    }
    printf("h2f_vaddr mmap successful\n");


    volatile uint8_t *wr_addr = h2f_vaddr + H2F_VRAM_INTERFACE_0_BASE + vram_offset;
    printf("Calculated Byte Address: %X\n", (uint32_t)wr_addr);

    uint64_t wr_data = strtoul(argv[4], NULL, 16);

    uint32_t wr_data_size = strtoul(argv[3], NULL, 10);
    switch (wr_data_size)
    {
        case 8:
            *wr_addr = (uint8_t)wr_data;
            break;
        case 16:
            *((uint16_t*)wr_addr) = (uint16_t)wr_data;
            break;
        case 32:
            *((uint32_t*)wr_addr) = (uint32_t)wr_data;
            break;
        case 64:
            *((uint64_t*)wr_addr) = (uint64_t)wr_data;
            break;
        default:
            fprintf(stderr, "Write Data Size incorrect. Please specify one of (8, 16, 32, 64)\n");
            close(mem);
            return -1;
    }

    return 0;
}