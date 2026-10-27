#include "../../apple/shared/NightPadEngineBridge.h"

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static int CaptureLaunch(NightPadEngineId, const char *, const void *, unsigned) {
    return 1;
}

static void *PlayThenStop(void *) {
    for (int i = 0; i < 1200 && NightPadDrivingEngineFrameCount() == 0; ++i)
        usleep(100000);
    const char *seconds = getenv("NIGHTPAD_PLAY_SECONDS");
    sleep(seconds != nullptr ? static_cast<unsigned>(atoi(seconds)) : 20);
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
        fprintf(stderr, "render cost: start failed\n");
        return 1;
    }
    pthread_t control;
    pthread_create(&control, nullptr, PlayThenStop, nullptr);
    NightPadDrivingEngineRunWindow();
    pthread_join(control, nullptr);
    NightPadDrivingEngineCloseWindow();
    const int joined = NightPadDrivingEngineJoin(30000);
    printf("render cost: frames=%lu joined=%d\n", NightPadDrivingEngineFrameCount(), joined);
    return joined ? 0 : 2;
}
