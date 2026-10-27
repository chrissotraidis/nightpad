// The only action-engine symbol exported from its combined iOS object. The coordinator
// starts this on a game-window-backed thread, exactly as the standalone macOS entry does.

#include "../../vendor/nightfire/src/action/engine/XboxStartup.h"

extern "C" unsigned NightPadActionEngineThread(void *unused) {
    return (unsigned)mainXapiStartup(unused);
}

