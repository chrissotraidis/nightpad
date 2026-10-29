#include "../../apple/shared/NightPadEngineBridge.h"

#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

static volatile int g_pauseHeld;
static volatile int g_resumed;
static volatile int g_booted;
static volatile int g_audioPaused;
static volatile int g_audioResumed;

// Keep the stop path in-process: the driving engine asks for DEFAULT.XBE as it
// shuts down, and without a coordinator that request exits the process.
static int CaptureLaunch(NightPadEngineId, const char *, const void *, unsigned) {
    return 1;
}

static void *ControlDriving(void *) {
    // Wait for the boot to reach the simulation loop.
    for (int i = 0; i < 1200 && NightPadDrivingEngineFrameCount() == 0; ++i)
        usleep(200000);
    g_booted = NightPadDrivingEngineFrameCount() > 0;
    for (int i = 0; i < 300 && NightPadDrivingEngineFrameCount() < 30; ++i)
        usleep(200000);

    NightPadDrivingEngineSetPaused(1);
    usleep(300000);
    const unsigned long first = NightPadDrivingEngineFrameCount();
    usleep(1500000);
    const unsigned long second = NightPadDrivingEngineFrameCount();
    g_pauseHeld = second - first <= 2;
    g_audioPaused = NightPadDrivingEngineAudioPaused() != 0;

    NightPadDrivingEngineSetPaused(0);
    usleep(1500000);
    const unsigned long third = NightPadDrivingEngineFrameCount();
    g_resumed = third > second;
    g_audioResumed = NightPadDrivingEngineAudioPaused() == 0;

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
        fprintf(stderr, "driving pause: start failed\n");
        return 1;
    }
    pthread_t control;
    pthread_create(&control, nullptr, ControlDriving, nullptr);
    NightPadDrivingEngineRunWindow();
    pthread_join(control, nullptr);
    NightPadDrivingEngineCloseWindow();
    const int joined = NightPadDrivingEngineJoin(30000);
    const int ok = g_booted && g_pauseHeld && g_resumed && g_audioPaused && g_audioResumed && joined;
    printf("driving pause: %s; frames=%lu booted=%d held=%d resumed=%d audio-paused=%d audio-resumed=%d "
           "joined=%d\n",
           ok ? "PASS" : "FAIL", NightPadDrivingEngineFrameCount(), g_booted, g_pauseHeld, g_resumed,
           g_audioPaused, g_audioResumed, joined);
    return ok ? 0 : 2;
}
