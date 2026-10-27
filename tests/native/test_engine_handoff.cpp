#include "../../apple/shared/NightPadEngineBridge.h"

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static volatile int g_launchCount;
static char g_launchImage[64];

// The coordinator takes every request: the requesting game thread ends without
// spawning a child process, and the harness starts the named engine next.
static int HandOff(NightPadEngineId engine, const char *image, const void *, unsigned bytes) {
    printf("[handoff] request engine=%d image=%s bytes=%u\n", (int)engine, image, bytes);
    snprintf(g_launchImage, sizeof(g_launchImage), "%s", image);
    ++g_launchCount;
    if (engine == NIGHTPAD_ENGINE_ACTION)
        NightPadActionEngineRequestStop();
    else
        NightPadDrivingEngineRequestStop();
    return 1;
}

static void *StopDrivingLater(void *) {
    const char *after = getenv("NIGHTPAD_HANDOFF_STOP_AFTER");
    sleep(after != nullptr ? static_cast<unsigned>(atoi(after)) : 150);
    NightPadDrivingEngineRequestStop();
    return nullptr;
}

static bool RequestsDriving(void) {
    return strcasestr(g_launchImage, "driving.xbe") != nullptr;
}

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    NightPadActionEngineSetLaunchRequestCallback(HandOff);
    NightPadDrivingEngineSetLaunchRequestCallback(HandOff);

    char program[] = "NightPad";
    char *actionArgv[] = { program, nullptr };
    char mission[] = "-mission";
    char missionNumber[] = "1";
    char *drivingArgv[] = { program, mission, missionNumber, nullptr };
    if (getenv("NIGHTPAD_HANDOFF_WARM_DRIVING") != nullptr) {
        if (!NightPadDrivingEngineStart(3, drivingArgv)) {
            fprintf(stderr, "handoff: warm driving start failed\n");
            return 5;
        }
        pthread_t warmStopper;
        pthread_create(&warmStopper, nullptr, StopDrivingLater, nullptr);
        NightPadDrivingEngineRunWindow();
        pthread_join(warmStopper, nullptr);
        NightPadDrivingEngineCloseWindow();
        if (!NightPadDrivingEngineJoin(30000)) {
            fprintf(stderr, "handoff: warm driving did not join\n");
            return 6;
        }
        printf("[handoff] warm driving joined\n");
        fflush(stdout);
    }
    if (!NightPadActionEngineStart(1, actionArgv)) {
        fprintf(stderr, "handoff: action start failed\n");
        return 1;
    }
    NightPadActionEngineTriggerDrivingAfter(90);
    NightPadActionEngineRunWindow();
    NightPadActionEngineCloseWindow();
    const int actionJoined = NightPadActionEngineJoin(30000);
    printf("[handoff] action joined=%d request=%s count=%d\n", actionJoined, g_launchImage, g_launchCount);
    if (!actionJoined || !RequestsDriving()) {
        fprintf(stderr, "handoff: action did not request the driving engine\n");
        return 2;
    }

    printf("[handoff] driving started\n");
    fflush(stdout);
    if (getenv("NIGHTPAD_HANDOFF_DROP_PAGE") != nullptr)
        unlink("psiLaunch.bin");
    if (!NightPadDrivingEngineStart(3, drivingArgv)) {
        fprintf(stderr, "handoff: driving start failed\n");
        return 3;
    }
    pthread_t stopper;
    pthread_create(&stopper, nullptr, StopDrivingLater, nullptr);
    NightPadDrivingEngineRunWindow();
    pthread_join(stopper, nullptr);
    NightPadDrivingEngineCloseWindow();
    const int drivingJoined = NightPadDrivingEngineJoin(30000);
    printf("[handoff] driving joined=%d count=%d\n", drivingJoined, g_launchCount);
    return drivingJoined ? 0 : 4;
}
