#pragma once

#include <stdint.h>

#include "Memory.h"

extern Memory g_memory;

class IO {
public:
    uint8_t in(uint8_t port);

    void out(
            uint8_t port,
            uint8_t value);

    void buildCpmImage();

};