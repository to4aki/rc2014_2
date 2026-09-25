#include "Memory.h"

void Memory::reset()
{
    for(int i = 0; i < SIZE; i++)
    {
        ram[i] = 0;
    }
}

uint8_t Memory::read(
        uint16_t address)
{
    return ram[address];
}

void Memory::write(
        uint16_t address,
        uint8_t value)
{
    ram[address] = value;
}