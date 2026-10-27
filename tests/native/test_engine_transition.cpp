#include "../../apple/shared/NightPadEngineBridge.h"

#include <mach/mach.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static volatile int g_launchCount;
static char g_launchImage[64];
static char g_lastLaunchImage[64];

static int CaptureLaunch(NightPadEngineId engine, const char *image, const void *, unsigned bytes) {
    printf("[transition] launch request engine=%d image=%s bytes=%u\n", (int)engine, image, bytes);
    if (g_launchCount == 0)
        snprintf(g_launchImage, sizeof(g_launchImage), "%s", image);
    snprintf(g_lastLaunchImage, sizeof(g_lastLaunchImage), "%s", image);
    ++g_launchCount;
    if (strstr(image, "DRIVING.XBE") != nullptr || strstr(image, "driving.xbe") != nullptr)
        NightPadActionEngineRequestStop();
    return 1;
}

static void *StopDriving(void *) {
    sleep(6);
    NightPadDrivingEngineRequestStop();
    return nullptr;
}

static mach_msg_type_number_t ThreadCount() {
    thread_act_array_t threads = nullptr;
    mach_msg_type_number_t count = 0;
    if (task_threads(mach_task_self(), &threads, &count) != KERN_SUCCESS)
        return 0;
    for (mach_msg_type_number_t i = 0; i < count; ++i)
        mach_port_deallocate(mach_task_self(), threads[i]);
    vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(threads),
                  count * sizeof(thread_t));
    return count;
}

int main(int argc, char **argv) {
    NightPadActionEngineSetLaunchRequestCallback(CaptureLaunch);
    NightPadDrivingEngineSetLaunchRequestCallback(CaptureLaunch);
    char actionProgram[] = "NightPad";
    char *actionArgv[] = { actionProgram, nullptr };
    const char *cycleText = getenv("NIGHTPAD_TRANSITION_CYCLES");
    int cycles = cycleText != nullptr ? atoi(cycleText) : 3;
    if (cycles < 1)
        cycles = 1;
    mach_msg_type_number_t settledFirst = 0;
    bool ok = true;
    for (int cycle = 0; cycle < cycles; ++cycle) {
        if (!NightPadDrivingEngineStart(argc, argv)) {
            fprintf(stderr, "transition: driving start failed on cycle %d\n", cycle + 1);
            return 1;
        }
        pthread_t drivingStopper;
        pthread_create(&drivingStopper, nullptr, StopDriving, nullptr);
        NightPadDrivingEngineRunWindow();
        pthread_join(drivingStopper, nullptr);
        NightPadDrivingEngineCloseWindow();
        int drivingJoined = NightPadDrivingEngineJoin(30000);

        if (!NightPadActionEngineStart(1, actionArgv)) {
            fprintf(stderr, "transition: action restart failed on cycle %d\n", cycle + 1);
            return 2;
        }
        NightPadActionEngineTriggerDrivingAfter(90);
        NightPadActionEngineRunWindow();
        NightPadActionEngineCloseWindow();
        int actionJoined = NightPadActionEngineJoin(30000);
        mach_msg_type_number_t settled = ThreadCount();
        if (cycle == 0)
            settledFirst = settled;
        bool drivingRequested = strstr(g_lastLaunchImage, "DRIVING.XBE") != nullptr ||
                                strstr(g_lastLaunchImage, "driving.xbe") != nullptr;
        bool cycleOk = drivingJoined && actionJoined && drivingRequested;
        ok = ok && cycleOk && settled <= settledFirst + 1;
        printf("transition cycle %d: launch-count=%d last=%s driving-join=%d action-join=%d threads=%u\n",
               cycle + 1, g_launchCount, g_lastLaunchImage, drivingJoined, actionJoined, settled);
    }
    ok = ok && g_launchCount >= cycles * 2 && strstr(g_launchImage, "DEFAULT.XBE") != nullptr;
    printf("transition: %s; cycles=%d launched=%d first=%s threads=%u\n",
           ok ? "PASS" : "FAIL", cycles, g_launchCount, g_launchImage, settledFirst);
    return ok ? 0 : 3;
}

