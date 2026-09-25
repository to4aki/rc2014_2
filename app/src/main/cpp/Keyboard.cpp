//
// Created by toshiaki_matsuyama on 2026/09/16.
//

#include "Keyboard.h"

#include "Keyboard.h"

void Keyboard::reset()
{
    readPos = 0;
    writePos = 0;
}

bool Keyboard::empty() const
{
    return readPos == writePos;
}

bool Keyboard::push(uint8_t key)
{
    int next =
            (writePos + 1) % SIZE;

    if(next == readPos)
    {
        return false;
    }

    buffer[writePos] = key;

    writePos = next;

    return true;
}

int Keyboard::pop()
{
    if(readPos == writePos)
    {
        return -1;
    }

    uint8_t key =
            buffer[readPos];

    readPos =
            (readPos + 1) % SIZE;

    return key;
}