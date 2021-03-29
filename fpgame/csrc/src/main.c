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
#define H2F_MMIO_BASE  (0xC0000000U)
#define H2F_MMIO_RANGE (0x3C000000U)

#define VRAM_BASE      (H2F_MMIO_BASE + H2F_VRAM_INTERFACE_0_BASE)

// All numbers are in terms of Bytes and are relative to H2F_MMIO_BASE + H2F_VRAM_INTERFACE_0_BASE
#define TILE_OFFSET    (0x0000U)
#define TILE_RANGE     (16384u)
//#define TILE_END       (0x3FFF)

#define PATTERN_OFFSET (0x4000U)
#define PATTERN_RANGE  (32768u)
//#define PATTERN_END    (0xBFFF)

#define PALETTE_OFFSET (0xC000U)
#define PALETTE_RANGE  (4096u)
#define PALETTE_END    (0xCFFF)

#define SPRITE_OFFSET  (0xD000U)
#define SPRITE_RANGE   (320U)
//#define SPRITE_END     (0xD13F)

#define VRAM_RANGE     (TILE_RANGE + PATTERN_RANGE + PALETTE_RANGE + SPRITE_RANGE)
// === TODO: MAKE VRAM HEADERS ===

// This function will return a MMIO-accessible byte-address into a VRAM segment given the id and rel
//   addr
uint8_t *calc_mmio_vram_offset (uint32_t vram_seg_id, uint32_t rel_addr)
{
    switch (vram_seg_id)
    {
        case 0:
            if (rel_addr < TILE_RANGE) return (uint8_t*)VRAM_BASE + TILE_OFFSET + rel_addr;
            break;
        case 1:
            if (rel_addr < PATTERN_RANGE) return (uint8_t*)VRAM_BASE + PATTERN_OFFSET + rel_addr;
            break;
        case 2:
            if (rel_addr < PALETTE_RANGE) return (uint8_t*)VRAM_BASE + PALETTE_OFFSET + rel_addr;
            break;
        case 3:
            if (rel_addr < SPRITE_RANGE) return (uint8_t*)VRAM_BASE + SPRITE_OFFSET + rel_addr;
            break;
        default:
            break;
    }

    return NULL;
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
    uint8_t *wr_addr;
    if ( !(wr_addr = calc_mmio_vram_offset(vram_seg_id, rel_addr)) )
    {
        fprintf(stderr, "Relative Address %X outside of %s RAM range\n", rel_addr,
                vram_seg_id_str[vram_seg_id]);
        return -1;
    }

    printf("Relative Address: %X\n", rel_addr);
    printf("Calculated Byte Address: %X\n", (uint32_t)wr_addr);
    printf("VRAM_BASE: %X\n", (uint32_t)VRAM_BASE);
    printf("VRAM_RANGE: %X\n", (uint32_t)VRAM_RANGE);

    /* First, we open memory as a file */
    int mem = open("/dev/mem", O_RDWR);
    if (mem < 0) {
        perror("Failed to open /dev/mem");
        return -1;
    }

    /* Next, we map the controllers MMIO */
    volatile uint8_t *vram_vaddr = mmap(NULL, VRAM_RANGE, PROT_WRITE,
                                        MAP_SHARED, mem, VRAM_BASE);
    if (vram_vaddr == MAP_FAILED) {
        perror("Failed to map H2F_MMIO address");
        close(mem);
        return -1;
    }

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