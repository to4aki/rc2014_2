#include "HexLoader.h"

#include <string>
#include <cstdint>
#include <sstream>

#include "Memory.h"

extern Memory g_memory;

static uint8_t hexDigit(char c)
{
    if(c >= '0' && c <= '9')
        return c - '0';

    if(c >= 'A' && c <= 'F')
        return c - 'A' + 10;

    if(c >= 'a' && c <= 'f')
        return c - 'a' + 10;

    return 0;
}

static uint8_t hexByte(
        const std::string& s,
        size_t pos)
{
    return (hexDigit(s[pos]) << 4)
           |  hexDigit(s[pos + 1]);
}

static uint16_t hexWord(
        const std::string& s,
        size_t pos)
{
    return (hexByte(s, pos) << 8)
           |  hexByte(s, pos + 2);
}

bool HexLoader::loadFromMemory(
        const char* data,
        size_t size)
{
    std::string text(
            data,
            size);

    std::istringstream file(text);

    std::string line;

    while(std::getline(file, line))
    {
        if(line.empty())
            continue;

        if(line[0] != ':')
            continue;

        uint8_t length =
                hexByte(line, 1);

        uint16_t address =
                hexWord(line, 3);

        uint8_t recordType =
                hexByte(line, 7);

        switch(recordType)
        {
            case 0x00:
            {
                for(uint8_t i = 0;
                    i < length;
                    i++)
                {
                    uint8_t value =
                            hexByte(
                                    line,
                                    9 + (i * 2));

                    g_memory.write(
                            address + i,
                            value);
                }

                break;
            }

            case 0x01:
                return true;

            default:
                break;
        }
    }

    return true;
}