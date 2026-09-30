#pragma once

#include <stdint.h>

class Console
{
public:
    void putChar(uint8_t ch);

    void clearScreen();
    void eraseToEndOfScreen();
    void insertLine(int row);

private:
    void scroll();

    void eraseToEndOfLine();

    void startEscape();
    void deleteChar();
    void processEscape(uint8_t ch);
    bool isEscapeComplete() const;
    void executeEscape();
};