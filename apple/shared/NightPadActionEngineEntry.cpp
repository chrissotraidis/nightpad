// The only action-engine symbol exported from its combined iOS object. The coordinator
// starts this on a game-window-backed thread, exactly as the standalone macOS entry does.

#include "../../vendor/nightfire/src/action/engine/XboxStartup.h"
#include "../../vendor/nightfire/src/common/launchInfo.h"
#include "../../vendor/nightfire/src/common/engineLifecycle.h"
#include "NightPadEngineBridge.h"

static NightPadLaunchRequestCallback g_launchRequestCallback = nullptr;

static bool ForwardLaunchRequest(const char *executableName, const void *page, unsigned bytes) {
    return g_launchRequestCallback != nullptr &&
           g_launchRequestCallback(NIGHTPAD_ENGINE_ACTION, executableName, page, bytes) != 0;
}

extern "C" void NightPadActionEngineSetLaunchRequestCallback(NightPadLaunchRequestCallback callback) {
    g_launchRequestCallback = callback;
    LaunchInfo_SetRequestHook(callback != nullptr ? ForwardLaunchRequest : nullptr);
}

extern "C" unsigned NightPadActionEngineThread(void *unused) {
    EngineLifecycle_ResetStop();
    return (unsigned)mainXapiStartup(unused);
}



