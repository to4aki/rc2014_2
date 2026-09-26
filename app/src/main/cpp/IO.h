#pragma once

#include <stdint.h>
#include <vector>
#include <ctype.h>
#include <strings.h>

#include "Memory.h"

extern Memory g_memory;

class IO {
public:
    uint8_t in(uint8_t port);

    void out(
            uint8_t port,
            uint8_t value);

    void buildCpmImage();

    void injectComFile(
            const char *filename,
            const uint8_t *data,
            size_t size);
};