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

uint8_t IO::in(uint8_t port)
{
    switch (port)
    {
        case 0x10:
            return cfSector[cfPos++ & 511];

        case 0x17:
            return 0x48;

            //
            // SIO A DATA
            //
        case 0x00:
        {
            int key = g_keyboardA.pop();

            if (key < 0)
            {
                return 0;
            }

            return (uint8_t)key;
        }

            //
            // SIO B DATA
            //
        case 0x01:
        {
            int key = g_keyboardB.pop();

            if (key < 0)
            {
                return 0;
            }

            return (uint8_t)key;
        }

            //
            // SIO A STATUS
            //
        case 0x02:
        {
            uint8_t status = 0x04;

            if (!g_keyboardA.empty())
            {
                status |= 0x01;
            }

            return status;
        }

            //
            // SIO B STATUS
            //
        case 0x03:
        {
            uint8_t status = 0x04;

            if (!g_keyboardB.empty())
            {
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
        uint8_t value)
{
    switch (port)
    {
        //
        // CF DATA
        //
        case 0x10:
        {
            cfSector[cfPos++] = value;

            if (cfPos >= 512)
            {
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
        case 0x17:
        {
            uint32_t lba =
                    cfLba0 |
                    (cfLba1 << 8) |
                    (cfLba2 << 16);

            //
            // READ SECTOR
            //
            if (value == 0x20)
            {
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

                if (size != 512)
                {
                    memset(
                            cfSector,
                            0xE5,
                            sizeof(cfSector));
                }
            }

            //
            // WRITE SECTOR
            //
            if (value == 0x30)
            {
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

void IO::buildCpmImage()
{
    //remove("/data/data/com.example.sample_c/files/disk.img");

    if (cfImage)
    {
        fclose(cfImage);
        cfImage = nullptr;
    }

    cfImage =
            fopen(
                    "/data/data/com.example.sample_c/files/disk.img",
                    "r+b");

    if (cfImage == nullptr)
    {
        cfImage =
                fopen(
                        "/data/data/com.example.sample_c/files/disk.img",
                        "w+b");

        if (cfImage)
        {
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
                 i++)
            {
                fwrite(
                        sector,
                        1,
                        sizeof(sector),
                        cfImage);
            }

            fflush(cfImage);
        }
    }

    if (cfImage == nullptr)
    {
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
         addr++)
    {
        fputc(
                g_memory.read(addr),
                cfImage);
    }

    fflush(cfImage);
}