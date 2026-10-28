// Product-side runtime for the isolated driving engine, mirroring the standalone main without process exit.

#include "../../vendor/nightfire/src/common/engineLifecycle.h"
#include "../../vendor/nightfire/src/driving/gfx/d3dSeam.h"
#include "../../vendor/nightfire/src/driving/platform/Host.h"
#include "../../vendor/nightfire/src/driving/platform/HostWindow.h"
#include "../../vendor/nightfire/src/driving/platform/HostInput.h"
#include "../../vendor/nightfire/src/driving/platform/KernelImports.h"
#include "../../vendor/nightfire/src/driving/platform/LaunchOptions.h"
#include "../../vendor/nightfire/src/driving/platform/XboxStartup.h"
#include "../../vendor/nightfire/src/driving/platform/XboxXapi.h"
#include "../../vendor/nightfire/src/common/fmv/Ffmpeg.h"
#include "../../vendor/nightfire/src/driving/audio/SoundManager.h"

#include "NightPadEngineBridge.h"

static HostHandle g_gameThread = nullptr;
static const size_t kGameStackSize = 0x10000;
static bool g_processServicesStarted = false;

extern "C" int NightPadDrivingEngineStart(int argc, char **argv) {
    if (g_gameThread != nullptr) {
        return 0;
    }
    HostSetCommandLine(argc, argv);
    Xbox_ApplyDiscPathSetting();
    if (!g_processServicesStarted) {
        KernelStart();
        D3dSeam_Init();
        Ffmpeg_Require();
        g_processServicesStarted = true;
    }
    Inject_LaunchOptions();
    D3dSeam_ResetDeviceForSession();
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

extern "C" int NightPadDrivingEnginePollWindow(void) {
    return HostWindow_Poll() ? 1 : 0;
}

extern "C" void NightPadDrivingEngineSetPaused(int paused) {
    if (paused)
        EngineLifecycle_RequestPause();
    else
        EngineLifecycle_ReleasePause();
}

extern "C" void NightPadDrivingEngineSetInputSuspended(int suspended) {
    HostInput_SetSuspended(suspended != 0);
}

extern "C" int NightPadDrivingEngineAudioPaused(void) {
    return ASoundManager_fgIsPaused ? 1 : 0;
}

static NightPadRumbleHandler g_rumbleHandler = nullptr;

static void ForwardRumble(int port, uint16_t leftMotor, uint16_t rightMotor) {
    if (g_rumbleHandler != nullptr)
        g_rumbleHandler(port, leftMotor, rightMotor);
}

extern "C" void NightPadDrivingEngineSetHostPadsEnabled(int enabled) {
    HostInput_SetHostPadsEnabled(enabled != 0);
    HostInput_SetRumbleHandler(enabled != 0 ? ForwardRumble : nullptr);
}

extern "C" void NightPadDrivingEngineSetHostPad(int port, unsigned buttons, int leftX, int leftY, int rightX,
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

extern "C" void NightPadDrivingEngineSetRumbleHandler(NightPadRumbleHandler handler) {
    g_rumbleHandler = handler;
    HostInput_SetRumbleHandler(handler != nullptr ? ForwardRumble : nullptr);
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

