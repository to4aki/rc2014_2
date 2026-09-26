#pragma once

#include <stdint.h>

class VRAM {
public:
    static const int COLS = 80;
    static const int ROWS = 43;
    static const int WIDTH  = COLS * 8;
    static const int HEIGHT = ROWS * 8;
    static const int DEBUG_ROWS = 3;
    static const int TEXT_ROWS = ROWS - DEBUG_ROWS;

    unsigned char text[ROWS][COLS];
    uint8_t colorTable[ROWS][COLS];

    int lineLength[ROWS];
    bool lineWrapped[ROWS];
    int cursorX;
    int cursorY;

    bool cursorVisible;
};
