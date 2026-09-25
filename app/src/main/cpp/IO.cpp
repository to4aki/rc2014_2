#include <android/log.h>
#include <string.h>

#include "IO.h"
#include "Keyboard.h"
#include "Console.h"

extern Keyboard g_keyboard;
extern Console g_console;

volatile uint8_t g_lastIoPort = 0;
static uint8_t aciaControl = 0;


static uint8_t cfSector[512];
static int cfPos = 0;

static uint8_t cfLba0 = 0;
static uint8_t cfLba1 = 0;
static uint8_t cfLba2 = 0;
static uint8_t cfLba3 = 0;

static uint8_t cfStatus = 0x48;

static uint8_t cpmImage[512 * 256];
static bool cpmImageReady = false;


uint8_t IO::in(uint8_t port) {
    g_lastIoPort = port;

    switch (port) {
        //
        // CF DATA
        //
        case 0x10: {
            extern uint8_t cfSector[512];
            extern int cfPos;

            uint8_t value =
                    cfSector[cfPos & 511];

            cfPos++;

            return value;
        }

            //
            // CF STATUS
            //
        case 0x17: {
            return 0x48;
        }

            //
            // SIO A DATA
            //
        case 0x00: {
            int key = g_keyboard.pop();

            __android_log_print(
                    ANDROID_LOG_ERROR,
                    "KEY",
                    "POP=%d",
                    key);

            if (key < 0) {
                return 0;
            }

            return (uint8_t) key;
        }

        case 0x01: {
            int key = g_keyboard.pop();

            __android_log_print(
                    ANDROID_LOG_ERROR,
                    "KEY",
                    "POP1=%d",
                    key);

            if (key < 0) {
                return 0;
            }

            return (uint8_t) key;
        }

        case 0x02: {
            uint8_t status = 0x04;

            if (!g_keyboard.empty()) {
                status |= 0x01;
            }

            __android_log_print(
                    ANDROID_LOG_ERROR,
                    "KEY",
                    "STATUS=%02X",
                    status);

            return status;
        }

        case 0x03: {
            uint8_t status = 0x04;

            if (!g_keyboard.empty()) {
                status |= 0x01;
            }

            __android_log_print(
                    ANDROID_LOG_ERROR,
                    "KEY",
                    "STATUS1=%02X",
                    status);

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
        // CF LBA
        //
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
            uint32_t lba = cfLba0;

            __android_log_print(
                    ANDROID_LOG_ERROR,
                    "CF",
                    "CMD=%02X LBA=%u",
                    value,
                    lba);

            if (value == 0x20) {
                cfPos = 0;

                if (lba < 24) {
                    memcpy(
                            cfSector,
                            &cpmImage[lba * 512],
                            512);
                } else {
                    //
                    // 空ディスク
                    // CP/M的には E5 が未使用
                    //
                    memset(
                            cfSector,
                            0xE5,
                            sizeof(cfSector));
                }
            }

            break;
        }

            //
            // Console
            //
        case 0x00:
            g_console.putChar(value);
            break;

        case 0x01:
            g_console.putChar(value);
            break;

        case 0x81:
            g_console.putChar(value);
            break;

        default:
            __android_log_print(
                    ANDROID_LOG_ERROR,
                    "IO",
                    "IN %02X",
                    port);
            break;
    }
}

void IO::buildCpmImage()
{
    memset(
            cpmImage,
            0xE5,
            sizeof(cpmImage));

    for(uint32_t addr = 0xD000;
        addr <= 0xFFFF;
        addr++)
    {
        cpmImage[addr - 0xD000] =
                g_memory.read(addr);
    }

    __android_log_print(
            ANDROID_LOG_ERROR,
            "CF",
            "CPM IMAGE READY");
}