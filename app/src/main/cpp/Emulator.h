#pragma once

#include "VRAM.h"
#include "Renderer.h"

class Emulator
{
public:
    VRAM vram;
    Renderer renderer;

    void reset();
    void frame();
};