// The only driving-engine symbol exported from its combined iOS object.

#include "../../vendor/nightfire/src/driving/platform/XboxStartup.h"

extern "C" unsigned NightPadDrivingEngineThread(void *unused) {
    return (unsigned)mainXapiStartup(unused);
}

