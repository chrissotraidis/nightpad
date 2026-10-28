// Product-side runtime for the isolated action engine. This replaces only the standalone main's setup and exit;
// the game startup and per-frame loop remain the reconstructed engine's.

#include "../../vendor/nightfire/src/common/engineLifecycle.h"
#include "../../vendor/nightfire/src/common/xboxPath.h"
#include "../../vendor/nightfire/src/action/devtools/Demo.h"
#include "../../vendor/nightfire/src/action/game.h"
#include "../../vendor/nightfire/src/action/sound/SFX.h"
#include "../../vendor/nightfire/src/action/engine/Fmv.h"
#include "../../vendor/nightfire/src/action/engine/LaunchOptions.h"
#include "../../vendor/nightfire/src/action/engine/XboxSettings.h"
#include "../../vendor/nightfire/src/action/engine/XboxStartup.h"
#include "../../vendor/nightfire/src/action/memory.h"
#include "../../vendor/nightfire/src/common/gfx/d3d9Backend.h"
#include "../../vendor/nightfire/src/driving/platform/Host.h"
#include "../../vendor/nightfire/src/driving/platform/HostWindow.h"
#include "../../vendor/nightfire/src/driving/platform/HostInput.h"

#include "NightPadEngineBridge.h"

#include <stdio.h>
#include <string.h>

static HostHandle g_gameThread = nullptr;

extern "C" int NightPadActionEngineStart(int argc, char **argv) {
    if (g_gameThread != nullptr) {
        return 0;
    }
    D3D9_ResetSessionCache();
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
    printf("[lifecycle] action join begin handle=%p timeout=%u ms\n", (void *)g_gameThread, timeoutMilliseconds);
    fflush(stdout);
    HostDword result = HostWaitForObject(g_gameThread, timeoutMilliseconds);
    if (result == 0) {
        printf("[lifecycle] action join complete\n");
        fflush(stdout);
        HostCloseHandle(g_gameThread);
        g_gameThread = nullptr;
        return 1;
    }
    // A long simulator frame can finish just after the timed wait returns.
    // The game thread is safe to reap once its exit code is available.
    HostDword exitCode = HOST_STILL_ACTIVE;
    if (HostGetExitCodeThread(g_gameThread, &exitCode) && exitCode != HOST_STILL_ACTIVE) {
        printf("[lifecycle] action join completed late with exit code %lu\n", (unsigned long)exitCode);
        fflush(stdout);
        HostCloseHandle(g_gameThread);
        g_gameThread = nullptr;
        return 1;
    }
    printf("[lifecycle] action join timed out; thread still active\n");
    fflush(stdout);
    return 0;
}

extern "C" void NightPadActionEngineCloseWindow(void) {
    HostWindow_Close();
}

extern "C" void NightPadActionEngineRequestStop(void) {
    printf("[lifecycle] action stop requested\n");
    fflush(stdout);
    EngineLifecycle_RequestStop();
    HostWindow_RequestQuit();
}

extern "C" void NightPadActionEngineSetPaused(int paused) {
    if (paused)
        EngineLifecycle_RequestPause();
    else
        EngineLifecycle_ReleasePause();
}

extern "C" void NightPadActionEngineSetInputSuspended(int suspended) {
    HostInput_SetSuspended(suspended != 0);
}

// The app's optional assists. The action loop applies these every frame so a
// codename load cannot quietly disable one.
extern "C" unsigned NightPadActionAssistFlags;

extern "C" void NightPadActionEngineSetAssistImmortal(int enabled) {
    if (enabled)
        NightPadActionAssistFlags |= 1u;
    else
        NightPadActionAssistFlags &= ~1u;
}

extern "C" void NightPadActionEngineSetAssistUnlimitedAmmo(int enabled) {
    if (enabled)
        NightPadActionAssistFlags |= 2u;
    else
        NightPadActionAssistFlags &= ~2u;
}

extern "C" unsigned NightPadActionEngineAppliedAssists(void) {
    return (CheatInfo.Immortal != 0 ? 1u : 0u) | (CheatInfo.UnlimitedAmmo != 0 ? 2u : 0u);
}

extern "C" int NightPadActionEngineAudioPaused(void) {
    return (SFXPaused != 0 && AllStreamsPaused != 0) ? 1 : 0;
}

static NightPadRumbleHandler g_rumbleHandler = nullptr;

static void ForwardRumble(int port, uint16_t leftMotor, uint16_t rightMotor) {
    if (g_rumbleHandler != nullptr)
        g_rumbleHandler(port, leftMotor, rightMotor);
}

extern "C" void NightPadActionEngineSetHostPadsEnabled(int enabled) {
    HostInput_SetHostPadsEnabled(enabled != 0);
    HostInput_SetRumbleHandler(enabled != 0 ? ForwardRumble : nullptr);
}

extern "C" void NightPadActionEngineSetHostPad(int port, unsigned buttons, int leftX, int leftY, int rightX,
                                                int rightY, unsigned leftTrigger, unsigned rightTrigger,
                                                int connected) {
    HostPadState state;
    memset(&state, 0, sizeof(state));
    state.buttons = static_cast<uint16_t>(buttons);
    state.thumbLX = static_cast<int16_t>(leftX);
    state.thumbLY = static_cast<int16_t>(leftY);
    state.thumbRX = static_cast<int16_t>(rightX);
    state.thumbRY = static_cast<int16_t>(rightY);
    state.leftTrigger = static_cast<uint8_t>(leftTrigger);
    state.rightTrigger = static_cast<uint8_t>(rightTrigger);
    HostInput_SetHostPad(port, connected != 0 ? &state : nullptr);
}

extern "C" void NightPadActionEngineSetRumbleHandler(NightPadRumbleHandler handler) {
    g_rumbleHandler = handler;
    HostInput_SetRumbleHandler(handler != nullptr ? ForwardRumble : nullptr);
}

