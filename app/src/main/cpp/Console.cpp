#include <string.h>
#include "VRAM.h"
#include "Console.h"

extern VRAM g_vram;

static void scrollScreen();

void Console::clearScreen()
{
    for(int y = 0;
        y < VRAM::TEXT_ROWS;
        y++)
    {
        for(int x = 0;
            x < VRAM::COLS;
            x++)
        {
            g_vram.text[y][x] = ' ';
            g_vram.colorTable[y][x] = 0x1F;
        }
    }

    g_vram.cursorX = 0;
    g_vram.cursorY = 0;
}

void Console::putChar(uint8_t ch)
{
    static bool escMode = false;
    static char escBuf[16];
    static int escPos = 0;

    if(ch == 0x1B)
    {
        escMode = true;
        escPos = 0;
        return;
    }
    if(escMode)
    {
        escBuf[escPos++] = ch;
        escBuf[escPos] = 0;

        if(ch == 'J')
        {
            if(strcmp(escBuf, "[2J") == 0)
            {
                clearScreen();
            }

            escMode = false;
        }

        return;
    }

    if(ch == '\b')
    {
        if(g_vram.cursorX > 0)
        {
            g_vram.cursorX--;
        }

        return;
    }

    if(ch == '\r')
    {
        g_vram.cursorX = 0;
        g_vram.cursorY++;

        if(g_vram.cursorY >= VRAM::TEXT_ROWS)
        {
            scroll();
            g_vram.cursorY =
                    VRAM::TEXT_ROWS - 1;
        }

        return;
    }

    g_vram.text[
            g_vram.cursorY
    ][
            g_vram.cursorX
    ] = ch;

    g_vram.colorTable[
            g_vram.cursorY
    ][
            g_vram.cursorX
    ] = 0x1F;

    g_vram.cursorX++;

    if(g_vram.cursorX >= VRAM::COLS)
    {
        g_vram.cursorX = 0;
        g_vram.cursorY++;

        if(g_vram.cursorY >= VRAM::TEXT_ROWS)
        {
            scroll();
            g_vram.cursorY =
                    VRAM::TEXT_ROWS - 1;
        }
    }
}

void Console::scroll()
{
    for (int y = 1; y < VRAM::TEXT_ROWS; y++)
    {
        for (int x = 0; x < VRAM::COLS; x++)
        {
            g_vram.text[y - 1][x] =
                    g_vram.text[y][x];

            g_vram.colorTable[y - 1][x] =
                    g_vram.colorTable[y][x];
        }

        g_vram.lineLength[y - 1] =
                g_vram.lineLength[y];

        g_vram.lineWrapped[y - 1] =
                g_vram.lineWrapped[y];
    }

    for (int x = 0; x < VRAM::COLS; x++)
    {
        g_vram.text[VRAM::TEXT_ROWS - 1][x] = ' ';
        g_vram.colorTable[VRAM::TEXT_ROWS - 1][x] = 0x1F;
    }
}