#pragma once

#include <stdint.h>

class Console
{
public:
    void putChar(uint8_t ch);
    void clearScreen();

private:
    void scroll();
};