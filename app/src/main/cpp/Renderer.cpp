#include <stdio.h>
#include <string.h>

#include "Renderer.h"
#include "VRAM.h"
#include "Memory.h"
#include "font8x8_basic.h"
#include "z80ex.h"
#include "z80ex_dasm.h"

constexpr int WIDTH = 640;
constexpr int HEIGHT = 344;

extern bool g_debugMode;
extern bool g_dasmMode;

extern uint16_t g_lastPort;
extern uint8_t g_lastKey;
extern uint64_t g_totalCycles;
extern double g_cpuMHz;
extern bool g_pause;

extern Z80EX_CONTEXT *g_cpu;
extern Memory g_memory;

constexpr int DEBUG_START_ROW = VRAM::TEXT_ROWS;

static const uint32_t palette[16] =
        {
                0xFF000000,
                0xFF0000AA,
                0xFF00AA00,
                0xFF00AAAA,
                0xFFAA0000,
                0xFFAA00AA,
                0xFFAA5500,
                0xFFAAAAAA,
                0xFF555555,
                0xFF5555FF,
                0xFF55FF55,
                0xFF55FFFF,
                0xFFFF5555,
                0xFFFF55FF,
                0xFFFFFF55,
                0xFFFFFFFF
        };

static Z80EX_BYTE dasmReadByte(
        Z80EX_WORD addr,
        void *user_data) {
    return g_memory.read(addr);
}

static void drawText(
        uint32_t *frameBuffer,
        int col,
        int row,
        const char *str) {
    while (*str) {
        unsigned char ch =
                (unsigned char) *str++;

        for (int fy = 0; fy < 8; fy++) {
            uint8_t bits =
                    font8x8_basic[ch][fy];

            for (int fx = 0; fx < 8; fx++) {
                int x = col * 8 + fx;
                int y = row * 8 + fy;

                bool on =
                        ((bits >> fx) & 1) != 0;

                frameBuffer[y * WIDTH + x] =
                        on
                        ? 0xFFFFFF55
                        : 0xFF0000AA;
            }
        }

        col++;
    }
}

static void drawRunInfo(
        uint32_t *frameBuffer) {
    char buf2[64];
    char buf3[64];
    char buf4[64];

    if (g_lastKey >= 32 &&
        g_lastKey <= 126) {
        snprintf(
                buf2,
                sizeof(buf2),
                "PC:%04X PORT:%02X KEY:%02X(%c)",
                z80ex_get_reg(
                        g_cpu,
                        regPC),
                g_lastPort & 0xFF,
                g_lastKey,
                g_lastKey);
    } else {
        snprintf(
                buf2,
                sizeof(buf2),
                "PC:%04X PORT:%02X KEY:%02X",
                z80ex_get_reg(
                        g_cpu,
                        regPC),
                g_lastPort & 0xFF,
                g_lastKey);
    }

    snprintf(
            buf3,
            sizeof(buf3),
            "CYC:%llu",
            (unsigned long long)
                    g_totalCycles);

    snprintf(
            buf4,
            sizeof(buf4),
            "CLK:%5.2fMHz",
            g_cpuMHz);

    drawText(
            frameBuffer,
            0,
            DEBUG_START_ROW + 0,
            buf2);

    drawText(
            frameBuffer,
            0,
            DEBUG_START_ROW + 1,
            buf3);

    drawText(
            frameBuffer,
            0,
            DEBUG_START_ROW + 2,
            buf4);
}

static void drawDisAssemble(
        uint32_t *frameBuffer) {
    if (g_dasmMode) {
        char buf[128];

        uint16_t pc =
                z80ex_get_reg(
                        g_cpu,
                        regPC);

        for (int row = DEBUG_START_ROW;
             row < VRAM::ROWS;
             row++) {

            int ts1 = 0;
            int ts2 = 0;

            int len =
                    z80ex_dasm(
                            buf,
                            sizeof(buf),
                            0,
                            &ts1,
                            &ts2,
                            dasmReadByte,
                            pc,
                            nullptr);

            char bytes[32] = "";

            for (int i = 0; i < len; i++) {
                char tmp[8];

                sprintf(
                        tmp,
                        "%02X ",
                        g_memory.read(pc + i));

                strcat(
                        bytes,
                        tmp);
            }

            char line[128];

            if (ts2) {
                snprintf(
                        line,
                        sizeof(line),
                        "%04X %-9s %-12s %d/%d",
                        pc,
                        bytes,
                        buf,
                        ts1,
                        ts2);
            } else {
                snprintf(
                        line,
                        sizeof(line),
                        "%04X %-9s %-12s %d",
                        pc,
                        bytes,
                        buf,
                        ts1);
            }

            drawText(
                    frameBuffer,
                    0,
                    row,
                    line);

            pc += len;
        }
    }
}

static void drawRegisters(
        uint32_t *frameBuffer) {
    char buf1[64];
    char buf2[64];
    char buf3[64];

    uint16_t af =
            z80ex_get_reg(
                    g_cpu,
                    regAF);

    uint8_t a =
            (af >> 8) & 0xFF;

    uint8_t f =
            af & 0xFF;

    snprintf(
            buf1,
            sizeof(buf1),
            "PC:%04X SP:%04X A:%02X F:%02X",
            z80ex_get_reg(
                    g_cpu,
                    regPC),
            z80ex_get_reg(
                    g_cpu,
                    regSP),
            a,
            f);

    snprintf(
            buf2,
            sizeof(buf2),
            "BC:%04X DE:%04X HL:%04X",
            z80ex_get_reg(
                    g_cpu,
                    regBC),
            z80ex_get_reg(
                    g_cpu,
                    regDE),
            z80ex_get_reg(
                    g_cpu,
                    regHL));

    snprintf(
            buf3,
            sizeof(buf3),
            "IX:%04X IY:%04X I:%02X R:%02X",
            z80ex_get_reg(
                    g_cpu,
                    regIX),
            z80ex_get_reg(
                    g_cpu,
                    regIY),
            z80ex_get_reg(
                    g_cpu,
                    regI),
            z80ex_get_reg(
                    g_cpu,
                    regR));

    drawText(
            frameBuffer,
            0,
            DEBUG_START_ROW + 0,
            buf1);

    drawText(
            frameBuffer,
            0,
            DEBUG_START_ROW + 1,
            buf2);

    drawText(
            frameBuffer,
            0,
            DEBUG_START_ROW + 2,
            buf3);
}

void Renderer::render(
        VRAM &vram,
        uint32_t *frameBuffer) {
    // 青背景
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            frameBuffer[y * WIDTH + x] = 0xFF0000AA;
        }
    }

    // 文字描画
    for (int row = 0;
         row < VRAM::TEXT_ROWS;
         row++) {

        for (int col = 0; col < VRAM::COLS; col++) {
            unsigned char ch =
                    vram.text[row][col];

            uint8_t attr =
                    vram.colorTable[row][col];

            uint8_t bg =
                    (attr >> 4) & 0x0F;

            uint8_t fg =
                    attr & 0x0F;

            //if (ch == ' ') {
            //    continue;
            //}

            for (int fy = 0; fy < 8; fy++) {
                // フォントテスト
                uint8_t bits =
                        font8x8_basic[ch][fy];

                for (int fx = 0; fx < 8; fx++) {
                    int x = col * 8 + fx;
                    int y = row * 8 + fy;

                    bool on =
                            ((bits >> fx) & 1) != 0;

                    frameBuffer[y * WIDTH + x] =
                            on
                            ? palette[fg]
                            : palette[bg];
                }
            }
        }
    }

    // デバッグ表示切替
    static int debugPage = 0;
    static int debugCounter = 0;

    debugCounter++;

    // デバッグ文字列表示
    if (g_cpu) {
        if (!g_pause) {
            drawRunInfo(
                    frameBuffer);
        } else if (g_dasmMode) {
            drawDisAssemble(
                    frameBuffer);
        } else {
            drawRegisters(
                    frameBuffer);
        }
    }

    // カーソル描画
    if (vram.cursorVisible) {
        int cx = vram.cursorX;
        int cy = vram.cursorY;

        for (
                int fx = 0;
                fx < 8; fx++) {
            int x = cx * 8 + fx;
            int y = cy * 8 + 7;

            if (x >= 0 && x < WIDTH &&
                y >= 0 && y < HEIGHT) {
                frameBuffer[
                        y * WIDTH
                        + x] =
                        0xFFFFFFFF;
            }
        }
    }
}