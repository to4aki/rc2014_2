#pragma once

#include <stddef.h>

class HexLoader
{
public:
    static bool loadFromMemory(
            const char* data,
            size_t size);
};