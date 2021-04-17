/** @file ppu.c
 * @author Joseph Yankel
 * @brief PPU library implementation
 */


// ================
// === Includes ===
// ================
#include <fp-game/ppu.h>
#include <fp-game/drv_ppu.h>
#include <noway.h>

#include <stdlib.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

// ======================
// === Implementation ===
// ======================
/** @brief The file descriptor for the PPU device file. */
static int ppu_fd = -1;

int ppu_enable(void)
{
    if (ppu_fd != -1)
    {
        fprintf(stderr, "FP-GAme PPU: PPU already enabled by this process!");
        return -1;
    }

    if ((ppu_fd = open(PPU_DEV_FILE, O_WRONLY)) < 0)
    {
        fprintf(stderr, "FP-GAme PPU: PPU could not be acquired! Error: %s\n", strerror(errno));
        return -1;
    }

    return 0;
}

void ppu_disable(void)
{
    if (ppu_fd == -1)
    {
        fprintf(stderr, "FP-GAme PPU: PPU already disabled by this process!");
    }

    close(ppu_fd);

    ppu_fd = -1;
}

int ppu_update(void)
{
    // if (ppu_fd == -1)
    // {
    //     fprintf(stderr, "FP-GAme PPU: ppu_update called while PPU is not enabled!");
    //     return -1;
    // }

    int ret;
    ret = ioctl(ppu_fd, IOCTL_PPU_UPDATE);

    return ret;
}

int ppu_write_vram(const void *buf, size_t len)
{
    if (write(ppu_fd, buf, len)) {
        fprintf(stderr, "FP-GAme PPU: PPU VRAM write failed! Error: %s\n", strerror(errno));
        return -1;
    }

    return 0;
}

int ppu_set_bgcolor(unsigned color)
{
    // if (ppu_fd == -1)
    // {
    //     fprintf(stderr, "FP-GAme PPU: ppu_set_bgcolor called while PPU is not enabled!");
    //     return -1;
    // }

    int ret;
    ret = ioctl(ppu_fd, IOCTL_PPU_SET_BGCOLOR, color & 0xFFFFFF);

    return ret;
}

int ppu_set_layer_enable(unsigned char enable_mask)
{
    // if (ppu_fd == -1)
    // {
    //     fprintf(stderr, "FP-GAme PPU: ppu_set_layer_enable called while PPU is not enabled!");
    //     return -1;
    // }

    int ret;
    ret = ioctl(ppu_fd, IOCTL_PPU_SET_ENABLE, enable_mask & 7);

    return ret;
}