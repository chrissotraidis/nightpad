// Product-side runtime for the isolated action engine. This replaces only the standalone main's setup and exit;
// the game startup and per-frame loop remain the reconstructed engine's.

#include "../../vendor/nightfire/src/common/engineLifecycle.h"
#include "../../vendor/nightfire/src/common/xboxPath.h"
#include "../../vendor/nightfire/src/action/devtools/Demo.h"
#include "../../vendor/nightfire/src/action/engine/Fmv.h"
#include "../../vendor/nightfire/src/action/engine/LaunchOptions.h"
#include "../../vendor/nightfire/src/action/engine/XboxSettings.h"
#include "../../vendor/nightfire/src/action/engine/XboxStartup.h"
#include "../../vendor/nightfire/src/action/memory.h"
#include "../../vendor/nightfire/src/driving/platform/Host.h"
#include "../../vendor/nightfire/src/driving/platform/HostWindow.h"

static HostHandle g_gameThread = nullptr;

extern "C" int NightPadActionEngineStart(int argc, char **argv) {
    if (g_gameThread != nullptr) {
        return 0;
    }
    HostSetCommandLine(argc, argv);
    LaunchOptions_Read();
    Demo_Init();
    Xbox_SetDiscRoot(Settings_GetDiscPath());
    Fmv_Init();
    Mem_TakeHeap();
    if (!HostWindow_Open(640, 480, "NightPad")) {
        return 0;
    }
    EngineLifecycle_ResetStop();
    g_gameThread = HostCreateThread(0x10000, mainXapiStartup, nullptr, 0, nullptr);
    return g_gameThread != nullptr;
}

extern "C" void NightPadActionEngineRunWindow(void) {
    HostWindow_Run();
}

extern "C" int NightPadActionEnginePollWindow(void) {
    return HostWindow_Poll() ? 1 : 0;
}

extern "C" int NightPadActionEngineJoin(unsigned timeoutMilliseconds) {
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

extern "C" void NightPadActionEngineCloseWindow(void) {
    HostWindow_Close();
}

extern "C" void NightPadActionEngineRequestStop(void) {
    EngineLifecycle_RequestStop();
    HostWindow_RequestQuit();
}

