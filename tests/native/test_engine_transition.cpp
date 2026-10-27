#include "../../apple/shared/NightPadEngineBridge.h"

#include <mach/mach.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static volatile int g_launchCount;
static char g_launchImage[64];

static int CaptureLaunch(NightPadEngineId engine, const char *image, const void *, unsigned bytes) {
    printf("[transition] launch request engine=%d image=%s bytes=%u\n", (int)engine, image, bytes);
    if (g_launchCount == 0)
        snprintf(g_launchImage, sizeof(g_launchImage), "%s", image);
    ++g_launchCount;
    return 1;
}

static void *StopAction(void *) {
    sleep(5);
    NightPadActionEngineRequestStop();
    return nullptr;
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

    if (!NightPadDrivingEngineStart(argc, argv)) {
        fprintf(stderr, "transition: driving start failed\n");
        return 1;
    }
    pthread_t drivingStopper;
    pthread_create(&drivingStopper, nullptr, StopDriving, nullptr);
    NightPadDrivingEngineRunWindow();
    pthread_join(drivingStopper, nullptr);
    NightPadDrivingEngineCloseWindow();
    int drivingJoined = NightPadDrivingEngineJoin(30000);
    mach_msg_type_number_t settledBeforeAction = ThreadCount();

    char actionProgram[] = "NightPad";
    char *actionArgv[] = { actionProgram, nullptr };
    if (!NightPadActionEngineStart(1, actionArgv)) {
        fprintf(stderr, "transition: action restart failed\n");
        return 2;
    }
    pthread_t actionStopper;
    pthread_create(&actionStopper, nullptr, StopAction, nullptr);
    NightPadActionEngineRunWindow();
    pthread_join(actionStopper, nullptr);
    NightPadActionEngineCloseWindow();
    int actionJoined = NightPadActionEngineJoin(30000);
    mach_msg_type_number_t settledAfterAction = ThreadCount();

    bool ok = drivingJoined && actionJoined && g_launchCount >= 1 &&
              strstr(g_launchImage, "DEFAULT.XBE") != nullptr &&
              settledAfterAction <= settledBeforeAction + 1;
    printf("transition: %s; launched=%d image=%s driving-join=%d action-join=%d threads=%u->%u\n",
           ok ? "PASS" : "FAIL", g_launchCount, g_launchImage, drivingJoined, actionJoined,
           settledBeforeAction, settledAfterAction);
    return ok ? 0 : 3;
}

