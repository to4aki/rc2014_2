#include <jni.h>
#include <stdint.h>
#include <stdio.h>
#include <chrono>

#include "VRAM.h"
#include "Renderer.h"
#include "Keyboard.h"
#include "IO.h"
#include "Memory.h"
#include "z80ex.h"
#include "Console.h"
#include "HexLoader.h"
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android/log.h>

AAssetManager *g_assetManager = nullptr;
VRAM g_vram;
Memory g_memory;
Renderer g_renderer;
Keyboard g_androidKeyboardA;
Keyboard g_keyboardA;
Keyboard g_keyboardB;
IO g_io;
Z80EX_CONTEXT *g_cpu = nullptr;
Console g_console;

constexpr int WIDTH = 640;
constexpr int HEIGHT = 344;

bool g_debugMode = true;
bool g_dasmMode = false;

bool g_pause = false;
bool g_step = false;
bool g_irqPending = false;

uint16_t g_lastPort = 0;
uint8_t g_lastKey = 0;
uint64_t g_totalCycles = 0;

static auto g_startTime =
        std::chrono::steady_clock::now();

double g_cpuMHz = 0.0;


/*
 * 毎フレーム new/delete しない
 */
static jint pixels[WIDTH * HEIGHT];

static Z80EX_BYTE cpu_read(
        Z80EX_CONTEXT *cpu,
        Z80EX_WORD addr,
        int m1_state,
        void *user_data) {
    return g_memory.read(addr);
}

static void cpu_write(
        Z80EX_CONTEXT *cpu,
        Z80EX_WORD addr,
        Z80EX_BYTE value,
        void *user_data) {
    g_memory.write(
            addr,
            value);
}

static Z80EX_BYTE cpu_in(
        Z80EX_CONTEXT *cpu,
        Z80EX_WORD port,
        void *user_data) {
    uint8_t p =
            static_cast<uint8_t>(port);

    return g_io.in(p);
}

static void cpu_out(
        Z80EX_CONTEXT *cpu,
        Z80EX_WORD port,
        Z80EX_BYTE value,
        void *user_data) {
    g_io.out(
            static_cast<uint8_t>(port),
            value);
}

static Z80EX_BYTE cpu_intread(
        Z80EX_CONTEXT *cpu,
        void *user_data) {
    uint8_t i =
            (uint8_t) z80ex_get_reg(
                    cpu,
                    regI);

    if (i == 0xFF) {
        return 0xE0;
    }

    return 0x60;
}


void importAllComFiles()
{
    AAssetDir *dir =
            AAssetManager_openDir(
                    g_assetManager,
                    "import");

    if (!dir)
    {
        __android_log_print(
                ANDROID_LOG_ERROR,
                "IMPORT",
                "DIR OPEN FAILED");
        return;
    }

    const char *fileName;

    while ((fileName = AAssetDir_getNextFileName(dir)) != nullptr)
    {
        char fullPath[256];

        snprintf(
                fullPath,
                sizeof(fullPath),
                "import/%s",
                fileName);

        AAsset *asset =
                AAssetManager_open(
                        g_assetManager,
                        fullPath,
                        AASSET_MODE_BUFFER);

        if (!asset)
        {
            continue;
        }

        const uint8_t *data =
                (const uint8_t *)AAsset_getBuffer(asset);

        size_t size =
                AAsset_getLength(asset);

        __android_log_print(
                ANDROID_LOG_ERROR,
                "IMPORT",
                "FILE=%s SIZE=%u",
                fileName,
                (unsigned)size);

        g_io.injectComFile(
                fileName,
                data,
                size);

        AAsset_close(asset);
    }

    AAssetDir_close(dir);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_sample_1c_NativeBridge_init(
        JNIEnv *env,
        jobject thiz,
        jobject assetManager) {
    g_vram.cursorVisible = true;

    for (int y = 0; y < VRAM::ROWS; y++) {
        for (int x = 0; x < VRAM::COLS; x++) {
            g_vram.text[y][x] = ' ';
            g_vram.colorTable[y][x] = 0x1F;
        }

        g_vram.lineLength[y] = 0;
        g_vram.lineWrapped[y] = false;
    }

    g_vram.cursorX = 0;
    g_vram.cursorY = 2;

    const char *msg = "Z80 EMULATOR V0.1";

    for (int i = 0; msg[i] != 0; i++) {
        g_vram.text[0][i] = msg[i];
        g_vram.colorTable[0][i] = 0x1E;
    }

    const char *msg2 = "READY.";

    for (int i = 0; msg2[i] != 0; i++) {
        g_vram.text[1][i] = msg2[i];
        g_vram.colorTable[1][i] = 0x1B;
    }

    g_androidKeyboardA.reset();
    g_keyboardA.reset();
    g_keyboardB.reset();
    g_memory.reset();
    g_cpu = z80ex_create(
            cpu_read,
            nullptr,

            cpu_write,
            nullptr,

            cpu_in,
            nullptr,

            cpu_out,
            nullptr,

            cpu_intread,
            nullptr);

    g_assetManager =
            AAssetManager_fromJava(
                    env,
                    assetManager);

    AAsset *asset =
            AAssetManager_open(
                    g_assetManager,
//                    "roms/rc2014_32k.hex",
                    "roms/ROM.HEX",
//                    "roms/MONITOR.HEX",
//                    "roms/CPM22.HEX",
//                    "roms/CBIOS64.HEX",
                    AASSET_MODE_BUFFER);

    const char *data =
            (const char *) AAsset_getBuffer(asset);

    size_t size =
            AAsset_getLength(asset);

    bool ok =
            HexLoader::loadFromMemory(
                    data,
                    size);

    asset =
            AAssetManager_open(
                    g_assetManager,
//                    "roms/rc2014_32k.hex",
//                    "roms/ROM.HEX",
                    "roms/CPM22.HEX",
//                    "roms/CBIOS64.HEX",
                    AASSET_MODE_BUFFER);

    data =
            (const char *) AAsset_getBuffer(asset);

    size =
            AAsset_getLength(asset);

    ok =
            HexLoader::loadFromMemory(
                    data,
                    size);

    asset =
            AAssetManager_open(
                    g_assetManager,
//                    "roms/rc2014_32k.hex",
//                    "roms/ROM.HEX",
//                    "roms/CPM22.HEX",
                    "roms/CBIOS64.HEX",
                    AASSET_MODE_BUFFER);

    data =
            (const char *) AAsset_getBuffer(asset);

    size =
            AAsset_getLength(asset);

    ok =
            HexLoader::loadFromMemory(
                    data,
                    size);

    g_io.buildCpmImage();

    //
    // DUMP.COM を注入
    //
    importAllComFiles();

    z80ex_reset(g_cpu);

    //z80ex_set_reg(
    //        g_cpu,
    //        regPC,
    //        0xD000);
}

static void scrollScreen() {
    for (int y = 1; y < VRAM::TEXT_ROWS; y++) {
        for (int x = 0; x < VRAM::COLS; x++) {
            g_vram.text[y - 1][x] =
                    g_vram.text[y][x];

            g_vram.colorTable[y - 1][x] =
                    g_vram.colorTable[y][x];
        }

        g_vram.lineLength[y - 1] =
                g_vram.lineLength[y];

        g_vram.lineWrapped[y - 1] =
                g_vram.lineWrapped[y];
    }

    for (int x = 0; x < VRAM::COLS; x++) {
        g_vram.text[VRAM::TEXT_ROWS - 1][x] = ' ';

        g_vram.colorTable[VRAM::TEXT_ROWS - 1][x] = 0x1F;
    }

    g_vram.lineLength[VRAM::TEXT_ROWS - 1] = 0;
    g_vram.lineWrapped[VRAM::TEXT_ROWS - 1] = false;
}

extern "C"
JNIEXPORT jintArray JNICALL
Java_com_example_sample_1c_NativeBridge_render(
        JNIEnv *env,
        jobject thiz)
{
    if (!g_pause)
    {
        //
        // Android入力キュー → CP/Mキュー
        //
        int moved = 0;

        while (!g_androidKeyboardA.empty()
               && moved < 1 )
        {
            int key =
                    g_androidKeyboardA.pop();

            if (key >= 0)
            {
                g_keyboardA.push(
                        static_cast<uint8_t>(key));

                g_irqPending = true;
            }

            moved++;
        }

        //
        // CPU実行
        //
        for (int i = 0; i < 200000; i++)
        {
            if (g_irqPending)
            {
                g_irqPending = false;

                z80ex_int(g_cpu);
            }

            g_totalCycles +=
                    z80ex_step(g_cpu);
        }
    }
    else if (g_step)
    {
        g_step = false;

        if (g_irqPending)
        {
            g_irqPending = false;

            z80ex_int(g_cpu);
        }

        g_totalCycles +=
                z80ex_step(g_cpu);
    }

    auto now =
            std::chrono::steady_clock::now();

    double elapsed =
            std::chrono::duration<double>(
                    now - g_startTime).count();

    if (elapsed > 0.0)
    {
        g_cpuMHz =
                (double)g_totalCycles /
                elapsed /
                1000000.0;
    }

    static int blinkCounter = 0;

    blinkCounter++;

    if (blinkCounter > 5)
    {
        blinkCounter = 0;

        g_vram.cursorVisible =
                !g_vram.cursorVisible;
    }

    jintArray array =
            env->NewIntArray(
                    WIDTH * HEIGHT);

    g_renderer.render(
            g_vram,
            reinterpret_cast<uint32_t *>(
                    pixels));

    env->SetIntArrayRegion(
            array,
            0,
            WIDTH * HEIGHT,
            pixels);

    return array;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_sample_1c_NativeBridge_keyPress(
        JNIEnv *env,
        jobject thiz,
        jint ch)
{
    bool ok =
            g_androidKeyboardA.push(
                    static_cast<uint8_t>(ch));

    if(!ok)
    {
        g_lastKey = '!';

        return;
    }

    g_lastKey =
            static_cast<uint8_t>(ch);

    g_irqPending = true;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_sample_1c_NativeBridge_toggleRun(
        JNIEnv *env,
        jobject thiz) {
    g_pause = !g_pause;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_sample_1c_NativeBridge_step(
        JNIEnv *env,
        jobject thiz) {
    if (g_pause) {
        g_step = true;
    }
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_sample_1c_NativeBridge_setDebugMode(
        JNIEnv *env,
        jobject thiz,
        jint mode) {
    g_dasmMode =
            (mode != 0);
}
