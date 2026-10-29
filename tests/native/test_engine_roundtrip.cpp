#include "../../apple/shared/NightPadEngineBridge.h"

#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

static volatile int g_launchCount;
static char g_lastImage[64];

static int HandOff(NightPadEngineId engine, const char *image, const void *, unsigned) {
    snprintf(g_lastImage, sizeof(g_lastImage), "%s", image != nullptr ? image : "");
    ++g_launchCount;
    if (engine == NIGHTPAD_ENGINE_ACTION)
        NightPadActionEngineRequestStop();
    else
        NightPadDrivingEngineRequestStop();
    return 1;
}

struct Phase {
    unsigned long (*frames)(void);
    unsigned long baseline;
    int seconds;
    bool driving;
    bool waitForLaunch;
};

static void *StopAfterFrames(void *argument) {
    Phase *phase = static_cast<Phase *>(argument);
    if (phase->waitForLaunch) {
        for (int i = 0; i < 1200 && g_launchCount == 0; ++i)
            usleep(200000);
        if (g_launchCount != 0)
            return nullptr;   // the hand-off already asked this engine to stop
    }
    for (int i = 0; i < 1200 && phase->frames() <= phase->baseline; ++i)
        usleep(200000);
    sleep(phase->seconds);
    if (phase->driving)
        NightPadDrivingEngineRequestStop();
    else
        NightPadActionEngineRequestStop();
    return nullptr;
}

static int RunPhase(bool driving, int seconds, bool waitForLaunch, unsigned long *reached) {
    Phase phase;
    phase.frames = driving ? NightPadDrivingEngineFrameCount : NightPadActionEngineFrameCount;
    phase.baseline = phase.frames();
    phase.seconds = seconds;
    phase.driving = driving;
    phase.waitForLaunch = waitForLaunch;
    pthread_t stopper;
    pthread_create(&stopper, nullptr, StopAfterFrames, &phase);
    if (driving)
        NightPadDrivingEngineRunWindow();
    else
        NightPadActionEngineRunWindow();
    pthread_join(stopper, nullptr);
    const unsigned long after = phase.frames();
    *reached = after > phase.baseline;
    if (driving) {
        NightPadDrivingEngineCloseWindow();
        return NightPadDrivingEngineJoin(30000);
    }
    NightPadActionEngineCloseWindow();
    return NightPadActionEngineJoin(30000);
}

int main() {
    NightPadActionEngineSetLaunchRequestCallback(HandOff);
    NightPadDrivingEngineSetLaunchRequestCallback(HandOff);
    char program[] = "NightPad";
    char *argv[] = { program, nullptr };
    char mission[] = "-mission";
    char missionNumber[] = "1";
    char *drivingArgv[] = { program, mission, missionNumber, nullptr };

    unsigned long reachedActionOne = 0, reachedDriving = 0, reachedActionTwo = 0;

    if (!NightPadActionEngineStart(1, argv))
        return 1;
    NightPadActionEngineTriggerDrivingAfter(90);
    const int firstActionQuit = RunPhase(false, 0, true, &reachedActionOne);
    const bool askedDriving = strcasestr(g_lastImage, "driving.xbe") != nullptr;

    if (!NightPadDrivingEngineStart(3, drivingArgv))
        return 2;
    const int drivingQuit = RunPhase(true, 2, false, &reachedDriving);
    const bool askedAction = strcasestr(g_lastImage, "default.xbe") != nullptr;

    if (!NightPadActionEngineStart(1, argv))
        return 3;
    const int secondActionQuit = RunPhase(false, 1, false, &reachedActionTwo);

    const bool ok = firstActionQuit && drivingQuit && secondActionQuit && askedDriving && askedAction &&
                    reachedActionOne && reachedDriving && reachedActionTwo;
    printf("roundtrip: %s; launches=%d first=%s last=%s action1=%d driving=%d action2=%d\n",
           ok ? "PASS" : "FAIL", g_launchCount, askedDriving ? "driving" : "?", askedAction ? "action" : "?",
           firstActionQuit, drivingQuit, secondActionQuit);
    return ok ? 0 : 4;
}
