#include "../../apple/shared/NightPadEngineBridge.h"

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static int CaptureLaunch(NightPadEngineId, const char *, const void *, unsigned) {
    return 1;
}

static void *StopDuringBoot(void *) {
    const char *after = getenv("NIGHTPAD_STOP_AFTER");
    sleep(after != nullptr ? static_cast<unsigned>(atoi(after)) : 2);
    NightPadDrivingEngineRequestStop();
    return nullptr;
}

int main() {
    NightPadDrivingEngineSetLaunchRequestCallback(CaptureLaunch);
    char program[] = "NightPad";
    char mission[] = "-mission";
    char missionNumber[] = "1";
    char *argv[] = { program, mission, missionNumber, nullptr };
    if (!NightPadDrivingEngineStart(3, argv)) {
        fprintf(stderr, "driving early stop: start failed\n");
        return 1;
    }
    pthread_t stopper;
    pthread_create(&stopper, nullptr, StopDuringBoot, nullptr);
    NightPadDrivingEngineRunWindow();
    pthread_join(stopper, nullptr);
    NightPadDrivingEngineCloseWindow();
    const int joined = NightPadDrivingEngineJoin(30000);
    printf("driving early stop: %s; frames=%lu joined=%d\n", joined ? "PASS" : "FAIL",
           NightPadDrivingEngineFrameCount(), joined);
    return joined ? 0 : 2;
}
