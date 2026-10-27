// The only driving-engine symbol exported from its combined iOS object.

#include "../../vendor/nightfire/src/driving/platform/XboxStartup.h"
#include "../../vendor/nightfire/src/common/launchInfo.h"
#include "NightPadEngineBridge.h"

static NightPadLaunchRequestCallback g_launchRequestCallback = nullptr;

static bool ForwardLaunchRequest(const char *executableName, const void *page, unsigned bytes) {
    return g_launchRequestCallback != nullptr &&
           g_launchRequestCallback(NIGHTPAD_ENGINE_DRIVING, executableName, page, bytes) != 0;
}

extern "C" void NightPadDrivingEngineSetLaunchRequestCallback(NightPadLaunchRequestCallback callback) {
    g_launchRequestCallback = callback;
    LaunchInfo_SetRequestHook(callback != nullptr ? ForwardLaunchRequest : nullptr);
}

extern "C" unsigned NightPadDrivingEngineThread(void *unused) {
    return (unsigned)mainXapiStartup(unused);
}

