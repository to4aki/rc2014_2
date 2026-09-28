//
// Created by toshiaki_matsuyama on 2026/09/16.
//

#include <android/log.h>
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
    __android_log_print(
            ANDROID_LOG_ERROR,
            "KBD",
            "PUSH %02X",
            key);

    {
        if(key == 0x80)
        {
            push(0x05);
            return true;
        }
        if(key == 0x81)
        {
            push(0x18);
            return true;
        }
        if(key == 0x82)
        {
            push(0x04);
            return true;
        }
        if(key == 0x83)
        {
            push(0x13);
            return true;
        }
    }

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