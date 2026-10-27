#include "../../apple/shared/NightPadEngineBridge.h"

#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

static volatile int g_booted;
static volatile int g_on;
static volatile int g_off;

static void *ControlAssists(void *) {
    for (int i = 0; i < 900 && NightPadActionEngineFrameCount() == 0; ++i)
        usleep(100000);
    g_booted = NightPadActionEngineFrameCount() > 0;

    NightPadActionEngineSetAssistImmortal(1);
    NightPadActionEngineSetAssistUnlimitedAmmo(1);
    usleep(600000);
    g_on = NightPadActionEngineAppliedAssists() == 3u;

    NightPadActionEngineSetAssistImmortal(0);
    NightPadActionEngineSetAssistUnlimitedAmmo(0);
    usleep(600000);
    g_off = NightPadActionEngineAppliedAssists() == 0u;

    NightPadActionEngineRequestStop();
    return nullptr;
}

int main() {
    char program[] = "NightPad";
    char *argv[] = { program, nullptr };
    if (!NightPadActionEngineStart(1, argv)) {
        fprintf(stderr, "assists: action start failed\n");
        return 1;
    }
    pthread_t control;
    pthread_create(&control, nullptr, ControlAssists, nullptr);
    NightPadActionEngineRunWindow();
    pthread_join(control, nullptr);
    NightPadActionEngineCloseWindow();
    const int joined = NightPadActionEngineJoin(30000);
    const int ok = g_booted && g_on && g_off && joined;
    printf("assists: %s; frames=%lu booted=%d on=%d off=%d joined=%d\n", ok ? "PASS" : "FAIL",
           NightPadActionEngineFrameCount(), g_booted, g_on, g_off, joined);
    return ok ? 0 : 2;
}
