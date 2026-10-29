#include "../../apple/shared/NightPadEngineBridge.h"
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

static bool ok;
static int CaptureLaunch(NightPadEngineId, const char *, const void *, unsigned) { return 1; }
static bool WaitMovie(bool paused, unsigned long minimum) {
    for (int i = 0; i < 6000; ++i) {
        unsigned long frames = 0;
        int held = 0;
        if (NightPadDrivingEngineMovieState(&frames, &held) && frames >= minimum && (held != 0) == paused)
            return true;
        usleep(10000);
    }
    return false;
}
static void *Control(void *) {
    if (!WaitMovie(false, 3)) {
        fprintf(stderr, "FAIL: intro did not begin\n");
        NightPadDrivingEngineRequestStop();
        return nullptr;
    }
    NightPadDrivingEngineSetPaused(1);
    if (!WaitMovie(true, 3)) {
        fprintf(stderr, "FAIL: intro did not observe native pause\n");
        NightPadDrivingEngineRequestStop();
        return nullptr;
    }
    unsigned long first = 0, second = 0;
    int paused = 0;
    NightPadDrivingEngineMovieState(&first, &paused);
    usleep(500000);
    NightPadDrivingEngineMovieState(&second, &paused);
    bool frozen = first == second && paused != 0;
    NightPadDrivingEngineSetPaused(0);
    bool resumed = WaitMovie(false, second + 3);
    NightPadDrivingEngineSetPaused(1);
    bool pausedAgain = WaitMovie(true, second + 3);
    ok = frozen && resumed && pausedAgain;
    printf("movie pause: frozen=%d (%lu -> %lu), resumed=%d, paused-again=%d, simulation=%lu\n",
           frozen, first, second, resumed, pausedAgain, NightPadDrivingEngineFrameCount());
    // Stopping must exit this paused movie, not wait for Resume or the ending.
    NightPadDrivingEngineRequestStop();
    bool leftMovie = false;
    for (int i = 0; i < 500; ++i) {
        if (!NightPadDrivingEngineMovieState(nullptr, nullptr)) { leftMovie = true; break; }
        usleep(10000);
    }
    ok = ok && leftMovie;
    if (!leftMovie) NightPadDrivingEngineSetPaused(0); // recover only to let a failed test terminate
    printf("movie stop while paused: exited-within-5s=%d\n", leftMovie);
    return nullptr;
}
int main() {
    NightPadDrivingEngineSetLaunchRequestCallback(CaptureLaunch);
    // The script supplies an isolated NTSC handover fixture. A -ntsc argument
    // is ignored on the original handover path, which already has video mode.
    char program[] = "NightPad", mission[] = "-mission", number[] = "1";
    char *argv[] = {program, mission, number, nullptr};
    for (int cycle = 0; cycle < 2; ++cycle) {
        ok = false;
        if (!NightPadDrivingEngineStart(3, argv)) return 1;
        NightPadDrivingEngineSetHostPadsEnabled(1);
        NightPadDrivingEngineSetHostPad(0, 0, 0, 0, 0, 0, 0, 0, 1);
        pthread_t control;
        pthread_create(&control, nullptr, Control, nullptr);
        NightPadDrivingEngineRunWindow();
        pthread_join(control, nullptr);
        NightPadDrivingEngineCloseWindow();
        int joined = NightPadDrivingEngineJoin(5000);
        printf("driving intro pause and stop cycle %d: %s; joined=%d\n", cycle + 1,
               ok && joined ? "PASS" : "FAIL", joined);
        if (!ok || !joined) return 1;
    }
    return 0;
}
