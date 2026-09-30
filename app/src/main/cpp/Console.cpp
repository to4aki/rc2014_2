#include <string.h>
#include <stdio.h>
#include <android/log.h>

#include "Console.h"
#include "VRAM.h"

extern VRAM g_vram;

static bool escMode = false;
static char escBuf[32];
static int escPos = 0;

static uint8_t currentAttr = 0x1F;

void Console::clearScreen()
{
    for (int y = 0; y < VRAM::TEXT_ROWS; y++) {

        for (int x = 0; x < VRAM::COLS; x++) {

            g_vram.text[y][x] = ' ';
            g_vram.colorTable[y][x] = 0x1F;
        }

        g_vram.lineLength[y] = 0;
        g_vram.lineWrapped[y] = false;
    }

    g_vram.cursorX = 0;
    g_vram.cursorY = 0;
}

void Console::eraseToEndOfLine()
{
    for (int x = g_vram.cursorX;
         x < VRAM::COLS;
         x++) {

        g_vram.text[g_vram.cursorY][x] = ' ';
        g_vram.colorTable[g_vram.cursorY][x] = 0x1F;
    }
}

void Console::eraseToEndOfScreen()
{
    int y = g_vram.cursorY;
    int x = g_vram.cursorX;

    for (int col = x;
         col < VRAM::COLS;
         col++) {

        g_vram.text[y][col] = ' ';
        g_vram.colorTable[y][col] = 0x1F;
    }

    for (int row = y + 1;
         row < VRAM::TEXT_ROWS;
         row++) {

        for (int col = 0;
             col < VRAM::COLS;
             col++) {

            g_vram.text[row][col] = ' ';
            g_vram.colorTable[row][col] = 0x1F;
        }
    }
}

void Console::insertLine(int row)
{
    if (row < 0 || row >= VRAM::TEXT_ROWS)
        return;

    for (int y = VRAM::TEXT_ROWS - 1;
         y > row;
         y--) {

        memcpy(
                g_vram.text[y],
                g_vram.text[y - 1],
                VRAM::COLS);

        memcpy(
                g_vram.colorTable[y],
                g_vram.colorTable[y - 1],
                VRAM::COLS);

        g_vram.lineLength[y] =
                g_vram.lineLength[y - 1];

        g_vram.lineWrapped[y] =
                g_vram.lineWrapped[y - 1];
    }

    for (int x = 0;
         x < VRAM::COLS;
         x++) {

        g_vram.text[row][x] = ' ';
        g_vram.colorTable[row][x] = 0x1F;
    }

    g_vram.lineLength[row] = 0;
    g_vram.lineWrapped[row] = false;
}

void Console::startEscape()
{
    escMode = true;
    escPos = 0;
    escBuf[0] = 0;
}

void Console::deleteChar()
{
    int y = g_vram.cursorY;
    int x = g_vram.cursorX;

    for (int col = x;
         col < VRAM::COLS - 1;
         col++) {

        g_vram.text[y][col] =
                g_vram.text[y][col + 1];

        g_vram.colorTable[y][col] =
                g_vram.colorTable[y][col + 1];
    }

    g_vram.text[y][VRAM::COLS - 1] = ' ';
    g_vram.colorTable[y][VRAM::COLS - 1] = 0x1F;
}

bool Console::isEscapeComplete() const
{
    if (escPos <= 0)
        return false;

    if (escBuf[0] == '=')
        return escPos == 3;

    //
    // ANSI CSI
    //
    if (escBuf[0] == '[') {

        char c = escBuf[escPos - 1];

        if ((c >= 'A' && c <= 'Z') ||
            (c >= 'a' && c <= 'z'))
            return true;

        return false;
    }

    //
    // TS803
    //
    return escPos == 1;
}

void Console::executeEscape()
{
    __android_log_print(
            ANDROID_LOG_ERROR,
            "TERM",
            "ESC=[%s]",
            escBuf);

    //
    // TS803
    //

    if (strcmp(escBuf, "E") == 0) {
        clearScreen();
        return;
    }

    if (strcmp(escBuf, "T") == 0) {
        return;
    }

    if (escBuf[0] == '=' &&
        escPos == 3) {

        int row =
                ((uint8_t)escBuf[1]) - 32;

        int col =
                ((uint8_t)escBuf[2]) - 32;

        if (row < 0)
            row = 0;

        if (col < 0)
            col = 0;

        if (row >= VRAM::TEXT_ROWS)
            row = VRAM::TEXT_ROWS - 1;

        if (col >= VRAM::COLS)
            col = VRAM::COLS - 1;

        g_vram.cursorY = row;
        g_vram.cursorX = col;

        return;
    }

    //
    // ANSI以外は無視
    //

    if (escBuf[0] != '[')
        return;

    //
    // ESC[H
    //

    if (strcmp(escBuf, "[H") == 0) {

        g_vram.cursorX = 0;
        g_vram.cursorY = 0;
        return;
    }

    //
    // ESC[row;colH
    //

    int row;
    int col;

    if (sscanf(
            escBuf,
            "[%d;%dH",
            &row,
            &col) == 2) {

        row--;
        col--;

        if (row < 0)
            row = 0;

        if (col < 0)
            col = 0;

        if (row >= VRAM::TEXT_ROWS)
            row = VRAM::TEXT_ROWS - 1;

        if (col >= VRAM::COLS)
            col = VRAM::COLS - 1;

        g_vram.cursorY = row;
        g_vram.cursorX = col;

        return;
    }

    //
    // ESC[J
    //

    if (strcmp(escBuf, "[J") == 0) {

        eraseToEndOfScreen();
        return;
    }

    //
    // ESC[2J
    //

    if (strcmp(escBuf, "[2J") == 0) {

        clearScreen();
        return;
    }

    //
    // ESC[K
    //

    if (strcmp(escBuf, "[K") == 0) {

        eraseToEndOfLine();
        return;
    }

    //
    // ESC[P
    // Delete Character
    //

    if (strcmp(escBuf, "[P") == 0) {

        deleteChar();
        return;
    }

    //
    // ESC[m
    //

    if (strcmp(escBuf, "[m") == 0 ||
        strcmp(escBuf, "[0m") == 0) {

        currentAttr = 0x1F;
        return;
    }

    //
    // ESC[1m
    //

    if (strcmp(escBuf, "[1m") == 0) {

        currentAttr = 0x1E;
        return;
    }

    //
    // ESC[L
    //

    if (strcmp(escBuf, "[L") == 0 ||
        strcmp(escBuf, "[1L") == 0) {

        insertLine(g_vram.cursorY);
        return;
    }

    //
    // ESC[nL
    //

    int count;

    if (sscanf(
            escBuf,
            "[%dL",
            &count) == 1) {

        while (count-- > 0)
            insertLine(g_vram.cursorY);

        return;
    }
}

void Console::processEscape(uint8_t ch)
{
    if (escPos < (int)sizeof(escBuf) - 1) {

        escBuf[escPos++] =
                (char)ch;

        escBuf[escPos] = 0;
    }

    if (!isEscapeComplete())
        return;

    executeEscape();

    escMode = false;
    escPos = 0;
    escBuf[0] = 0;
}

void Console::putChar(uint8_t ch)
{
    if (escMode) {

        processEscape(ch);
        return;
    }

    switch (ch) {

        case 0x1B:

            startEscape();
            return;

        case 0x0C:

            clearScreen();
            return;

        case '\b':

            if (g_vram.cursorX > 0)
                g_vram.cursorX--;

            return;

        case '\r':

            g_vram.cursorX = 0;
            return;

        case '\n':

            g_vram.cursorY++;

            if (g_vram.cursorY >=
                VRAM::TEXT_ROWS) {

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
    ] = currentAttr;

    g_vram.cursorX++;

    if (g_vram.cursorX >= VRAM::COLS) {

        g_vram.cursorX = 0;
        g_vram.cursorY++;

        if (g_vram.cursorY >=
            VRAM::TEXT_ROWS) {

            scroll();

            g_vram.cursorY =
                    VRAM::TEXT_ROWS - 1;
        }
    }
}

void Console::scroll()
{
    for (int y = 1;
         y < VRAM::TEXT_ROWS;
         y++) {

        memcpy(
                g_vram.text[y - 1],
                g_vram.text[y],
                VRAM::COLS);

        memcpy(
                g_vram.colorTable[y - 1],
                g_vram.colorTable[y],
                VRAM::COLS);

        g_vram.lineLength[y - 1] =
                g_vram.lineLength[y];

        g_vram.lineWrapped[y - 1] =
                g_vram.lineWrapped[y];
    }

    int last = VRAM::TEXT_ROWS - 1;

    for (int x = 0;
         x < VRAM::COLS;
         x++) {

        g_vram.text[last][x] = ' ';
        g_vram.colorTable[last][x] = 0x1F;
    }

    g_vram.lineLength[last] = 0;
    g_vram.lineWrapped[last] = false;
}