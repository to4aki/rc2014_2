#include <android/log.h>
#include <string.h>
#include <stdio.h>

#include "IO.h"
#include "Keyboard.h"
#include "Console.h"

extern Keyboard g_keyboardA;
extern Keyboard g_keyboardB;
extern Console g_console;

static uint8_t cfSector[512];

static int cfPos = 0;

static uint8_t cfLba0 = 0;
static uint8_t cfLba1 = 0;
static uint8_t cfLba2 = 0;
static uint8_t cfLba3 = 0;

static FILE *cfImage = nullptr;

static long blockOffset(int block)
{
    //
    // Grant Searle CP/M
    //
    // OFF=1 track
    // 1 track = 128 CP/M sectors
    // 128 * 128 = 16384 bytes
    //
    return
            16384L +
            ((long)block * 4096L);
}

uint8_t IO::in(uint8_t port) {
    switch (port) {
        case 0x10:
            return cfSector[cfPos++ & 511];

        case 0x17:
            return 0x48;

            //
            // SIO A DATA
            //
        case 0x00: {
            int key;
            int last = -1;

            while ((key = g_keyboardA.pop()) >= 0) {
                last = key;
            }

            if (last < 0) {
                return 0;
            }

            return (uint8_t) last;
        }

            //
            // SIO B DATA
            //
        case 0x01: {
            int key;
            int last = -1;

            while ((key = g_keyboardB.pop()) >= 0) {
                last = key;
            }

            if (last < 0) {
                return 0;
            }

            return (uint8_t) last;
        }

            //
            // SIO A STATUS
            //
        case 0x02: {
            uint8_t status = 0x04;

            if (!g_keyboardA.empty()) {
                status |= 0x01;
            }

            return status;
        }

            //
            // SIO B STATUS
            //
        case 0x03: {
            uint8_t status = 0x04;

            if (!g_keyboardB.empty()) {
                status |= 0x01;
            }

            return status;
        }

        default:
            return 0;
    }
}

void IO::out(
        uint8_t port,
        uint8_t value) {
    switch (port) {
        //
        // CF DATA
        //
        case 0x10: {
            cfSector[cfPos++] = value;

            if (cfPos >= 512) {
                uint32_t lba =
                        cfLba0 |
                        (cfLba1 << 8) |
                        (cfLba2 << 16);

                fseek(
                        cfImage,
                        lba * 512,
                        SEEK_SET);

                fwrite(
                        cfSector,
                        1,
                        512,
                        cfImage);

                fflush(cfImage);

                cfPos = 0;
            }

            break;
        }

        case 0x13:
            cfLba0 = value;
            break;

        case 0x14:
            cfLba1 = value;
            break;

        case 0x15:
            cfLba2 = value;
            break;

        case 0x16:
            cfLba3 = value;
            break;

            //
            // CF COMMAND
            //
        case 0x17: {
            uint32_t lba =
                    cfLba0 |
                    (cfLba1 << 8) |
                    (cfLba2 << 16);

            //
            // READ SECTOR
            //
            if (value == 0x20) {
                cfPos = 0;

                fseek(
                        cfImage,
                        lba * 512,
                        SEEK_SET);

                size_t size =
                        fread(
                                cfSector,
                                1,
                                512,
                                cfImage);

                if (size != 512) {
                    memset(
                            cfSector,
                            0xE5,
                            sizeof(cfSector));
                }
            }

            //
            // WRITE SECTOR
            //
            if (value == 0x30) {
                cfPos = 0;
            }

            break;
        }

            //
            // Console
            //
        case 0x00:
        case 0x01:
        case 0x81:
            g_console.putChar(value);
            break;

        default:
            break;
    }
}

void IO::buildCpmImage() {
    remove("/data/data/com.example.sample_c/files/disk.img");

    if (cfImage) {
        fclose(cfImage);
        cfImage = nullptr;
    }

    cfImage =
            fopen(
                    "/data/data/com.example.sample_c/files/disk.img",
//                    "/storage/emulated/0/Download/disk.img",
                    "r+b");

    if (cfImage == nullptr) {
        cfImage =
                fopen(
                        "/data/data/com.example.sample_c/files/disk.img",
//                        "/storage/emulated/0/Download/disk.img",
                        "w+b");

        if (cfImage) {
            uint8_t sector[512];

            memset(
                    sector,
                    0xE5,
                    sizeof(sector));

            //
            // 64MB CompactFlash
            //
            for (uint32_t i = 0;
                 i < (64U * 1024U * 1024U) / 512U;
                 i++) {
                fwrite(
                        sector,
                        1,
                        sizeof(sector),
                        cfImage);
            }

            fflush(cfImage);
        }
    }

    if (cfImage == nullptr) {
        __android_log_print(
                ANDROID_LOG_ERROR,
                "CF",
                "IMAGE OPEN FAILED");

        return;
    }

    //
    // CP/M boot sectors
    //
    fseek(
            cfImage,
            0,
            SEEK_SET);

    for (uint32_t addr = 0xD000;
         addr <= 0xFFFF;
         addr++) {
        fputc(
                g_memory.read(addr),
                cfImage);
    }

    fflush(cfImage);
}


void IO::injectComFile(
        const char *filename,
        const uint8_t *data,
        size_t size)
{
    uint8_t directory[2048];

    fseek(
            cfImage,
            32 * 512,
            SEEK_SET);

    fread(
            directory,
            1,
            sizeof(directory),
            cfImage);

    char name[8];
    char ext[3];

    memset(name, ' ', sizeof(name));
    memset(ext,  ' ', sizeof(ext));

    const char *dot = strchr(filename, '.');

    if (dot)
    {
        int n = (int)(dot - filename);

        if (n > 8)
        {
            n = 8;
        }

        memcpy(
                name,
                filename,
                n);

        const char *e = dot + 1;

        int m = (int)strlen(e);

        if (m > 3)
        {
            m = 3;
        }

        memcpy(
                ext,
                e,
                m);
    }
    else
    {
        int n = (int)strlen(filename);

        if (n > 8)
        {
            n = 8;
        }

        memcpy(
                name,
                filename,
                n);
    }

    static uint16_t nextBlock = 4;

    size_t fileOffset = 0;

    while (fileOffset < size)
    {
        int freeEntry = -1;

        for (int i = 0; i < 64; i++)
        {
            if (directory[i * 32] == 0xE5)
            {
                freeEntry = i;
                break;
            }
        }

        if (freeEntry < 0)
        {
            __android_log_print(
                    ANDROID_LOG_ERROR,
                    "CPM",
                    "DIRECTORY FULL");

            return;
        }

        uint8_t *dir =
                &directory[freeEntry * 32];

        memset(
                dir,
                0,
                32);

        dir[0] = 0;

        memcpy(
                &dir[1],
                name,
                8);

        memcpy(
                &dir[9],
                ext,
                3);

        size_t extentBytes =
                size - fileOffset;

        if (extentBytes > 32768)
        {
            extentBytes = 32768;
        }

        int records =
                (int)((extentBytes + 127) / 128);

        //
        // EXM=1 仮説
        //
        int ex;

        if (records >= 128)
        {
            ex = 1;

            if (records > 128)
            {
                records -= 128;
            }
            else
            {
                records = 0x80;
            }
        }
        else
        {
            ex = 0;
        }

        dir[12] = (uint8_t)ex;
        dir[13] = 0;
        dir[14] = 0;
        dir[15] = (uint8_t)records;

        memset(
                &dir[16],
                0,
                16);

        int blockCount =
                (int)((extentBytes + 4095)
                      / 4096);

        if (blockCount > 8)
        {
            blockCount = 8;
        }

        for (int blockIndex = 0;
             blockIndex < blockCount;
             blockIndex++)
        {
            uint16_t block =
                    nextBlock++;

            dir[16 + blockIndex * 2] =
                    (uint8_t)(block & 0xFF);

            dir[17 + blockIndex * 2] =
                    (uint8_t)(block >> 8);

            uint8_t buffer[4096];

            memset(
                    buffer,
                    0x1A,
                    sizeof(buffer));

            size_t src =
                    fileOffset +
                    (size_t)blockIndex * 4096;

            size_t remain =
                    extentBytes -
                    (size_t)blockIndex * 4096;

            size_t copy =
                    remain;

            if (copy > 4096)
            {
                copy = 4096;
            }

            memcpy(
                    buffer,
                    data + src,
                    copy);

            fseek(
                    cfImage,
                    blockOffset(block),
                    SEEK_SET);

            fwrite(
                    buffer,
                    1,
                    sizeof(buffer),
                    cfImage);
        }

        fileOffset += extentBytes;
    }

    fseek(
            cfImage,
            32 * 512,
            SEEK_SET);

    fwrite(
            directory,
            1,
            sizeof(directory),
            cfImage);

    fflush(cfImage);
}