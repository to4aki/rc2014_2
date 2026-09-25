#pragma once

#include <stdint.h>

class Memory
{
public:
    static const int SIZE = 65536;

    uint8_t ram[SIZE];

    void reset();

    uint8_t read(uint16_t address);

    void write(
            uint16_t address,
            uint8_t value);
};