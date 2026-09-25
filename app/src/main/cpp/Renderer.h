#pragma once

#include <stdint.h>
#include "VRAM.h"

enum DebugMode
{
    DEBUG_REG = 0,
    DEBUG_DASM = 1
};

class Renderer
{
public:
    void render(
            VRAM& vram,
            uint32_t* frameBuffer);
};