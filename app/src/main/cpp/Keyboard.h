#pragma once

#include <stdint.h>

class Keyboard
{
public:
    static const int SIZE = 4096;

    uint8_t buffer[SIZE];

    int readPos;
    int writePos;

    bool empty() const;

    void reset();

    bool push(uint8_t key);

    int pop();
};