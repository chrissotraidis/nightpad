// Product-side runtime for the isolated driving engine, mirroring the standalone main without process exit.

#include "../../vendor/nightfire/src/common/engineLifecycle.h"
#include "../../vendor/nightfire/src/driving/gfx/d3dSeam.h"
#include "../../vendor/nightfire/src/driving/platform/Host.h"
#include "../../vendor/nightfire/src/driving/platform/HostWindow.h"
#include "../../vendor/nightfire/src/driving/platform/KernelImports.h"
#include "../../vendor/nightfire/src/driving/platform/LaunchOptions.h"
#include "../../vendor/nightfire/src/driving/platform/XboxStartup.h"
#include "../../vendor/nightfire/src/driving/platform/XboxXapi.h"
#include "../../vendor/nightfire/src/common/fmv/Ffmpeg.h"

static HostHandle g_gameThread = nullptr;
static const size_t kGameStackSize = 0x10000;

extern "C" int NightPadDrivingEngineStart(int argc, char **argv) {
    if (g_gameThread != nullptr) {
        return 0;
    }
    HostSetCommandLine(argc, argv);
    KernelStart();
    Xbox_ApplyDiscPathSetting();
    D3dSeam_Init();
    Inject_LaunchOptions();
    Ffmpeg_Require();
    if (!HostWindow_Open(640, 480, "NightPad")) {
        return 0;
    }
    EngineLifecycle_ResetStop();
    g_gameThread = HostCreateThread(kGameStackSize, mainXapiStartup, nullptr, 0, nullptr);
    return g_gameThread != nullptr;
}

extern "C" void NightPadDrivingEngineRunWindow(void) {
    HostWindow_Run();
}

extern "C" int NightPadDrivingEngineJoin(unsigned timeoutMilliseconds) {
    if (g_gameThread == nullptr) {
        return 1;
    }
    HostDword result = HostWaitForObject(g_gameThread, timeoutMilliseconds);
    if (result == 0) {
        HostCloseHandle(g_gameThread);
        g_gameThread = nullptr;
        return 1;
    }
    return 0;
}

extern "C" void NightPadDrivingEngineCloseWindow(void) {
    HostWindow_Close();
}

