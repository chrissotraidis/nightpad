#include "../../apple/shared/NightPadEngineBridge.h"

#include <mach/mach.h>
#include <mach/task_info.h>
#include <mach/thread_info.h>
#include <dlfcn.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <atomic>

#if defined(NIGHTPAD_DRIVING_LIFECYCLE)
#define ENGINE_START NightPadDrivingEngineStart
#define ENGINE_RUN_WINDOW NightPadDrivingEngineRunWindow
#define ENGINE_JOIN NightPadDrivingEngineJoin
#define ENGINE_CLOSE_WINDOW NightPadDrivingEngineCloseWindow
#define ENGINE_REQUEST_STOP NightPadDrivingEngineRequestStop
#define ENGINE_SET_LAUNCH_CALLBACK NightPadDrivingEngineSetLaunchRequestCallback
#else
#define ENGINE_START NightPadActionEngineStart
#define ENGINE_RUN_WINDOW NightPadActionEngineRunWindow
#define ENGINE_JOIN NightPadActionEngineJoin
#define ENGINE_CLOSE_WINDOW NightPadActionEngineCloseWindow
#define ENGINE_REQUEST_STOP NightPadActionEngineRequestStop
#define ENGINE_SET_LAUNCH_CALLBACK NightPadActionEngineSetLaunchRequestCallback
#endif

static mach_msg_type_number_t ThreadCount() {
    thread_act_array_t threads = nullptr;
    mach_msg_type_number_t count = 0;
    if (task_threads(mach_task_self(), &threads, &count) != KERN_SUCCESS) {
        return 0;
    }
    for (mach_msg_type_number_t i = 0; i < count; ++i) {
        mach_port_deallocate(mach_task_self(), threads[i]);
    }
    vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(threads),
                  count * sizeof(thread_t));
    return count;
}

static unsigned long long ResidentBytes() {
    task_vm_info_data_t info = {};
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, reinterpret_cast<task_info_t>(&info), &count) != KERN_SUCCESS)
        return 0;
    return static_cast<unsigned long long>(info.phys_footprint);
}

static void DumpThreads(const char *label) {
    thread_act_array_t threads = nullptr;
    mach_msg_type_number_t count = 0;
    if (task_threads(mach_task_self(), &threads, &count) != KERN_SUCCESS)
        return;
    printf("[threads] %s: %u\n", label, count);
    for (mach_msg_type_number_t i = 0; i < count; ++i) {
        thread_identifier_info_data_t identifier = {};
        mach_msg_type_number_t identifierCount = THREAD_IDENTIFIER_INFO_COUNT;
        thread_extended_info_data_t extended = {};
        mach_msg_type_number_t extendedCount = THREAD_EXTENDED_INFO_COUNT;
        thread_info(threads[i], THREAD_IDENTIFIER_INFO,
                    reinterpret_cast<thread_info_t>(&identifier), &identifierCount);
        thread_info(threads[i], THREAD_EXTENDED_INFO,
                    reinterpret_cast<thread_info_t>(&extended), &extendedCount);
        arm_thread_state64_t state = {};
        mach_msg_type_number_t stateCount = ARM_THREAD_STATE64_COUNT;
        thread_get_state(threads[i], ARM_THREAD_STATE64,
                         reinterpret_cast<thread_state_t>(&state), &stateCount);
        Dl_info image = {};
        const void *address = reinterpret_cast<const void *>(state.__pc);
        const char *symbol = dladdr(address, &image) != 0 && image.dli_sname != nullptr
                                 ? image.dli_sname : "?";
        printf("[threads] id=%llu state=%d cpu=%d name=%.*s symbol=%s\n",
               static_cast<unsigned long long>(identifier.thread_id), extended.pth_run_state,
               extended.pth_cpu_usage, MAXTHREADNAMESIZE, extended.pth_name, symbol);
        mach_port_deallocate(mach_task_self(), threads[i]);
    }
    vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(threads),
                  count * sizeof(thread_t));
}

static std::atomic<bool> g_pauseCancel{false};
static std::atomic<bool> g_pauseDone{false};
static std::atomic<bool> g_pauseOk{false};

static void *StopLater(void *) {
    int seconds = 6;
    const char *stopAfter = getenv("NIGHTPAD_STOP_AFTER_S");
    if (stopAfter != nullptr && atoi(stopAfter) > 0)
        seconds = atoi(stopAfter);
    sleep(static_cast<unsigned>(seconds));
    g_pauseCancel.store(true);
    printf("[lifecycle] watchdog requesting stop\n");
    fflush(stdout);
    ENGINE_REQUEST_STOP();
    printf("[lifecycle] watchdog stop returned\n");
    fflush(stdout);
    return nullptr;
}

static int CaptureLaunch(NightPadEngineId, const char *image, const void *, unsigned bytes) {
    printf("[lifecycle] in-process launch request: %s (%u bytes)\n", image, bytes);
    return 1;
}

#ifndef NIGHTPAD_DRIVING_LIFECYCLE
static void *PauseProbe(void *) {
    unsigned long first = NightPadActionEngineFrameCount();
    for (int wait = 0; wait < 1500 && !g_pauseCancel.load() && NightPadActionEngineFrameCount() == first; ++wait)
        usleep(10000);
    if (g_pauseCancel.load()) {
        g_pauseOk.store(false);
        g_pauseDone.store(true);
        return nullptr;
    }
    unsigned long running = NightPadActionEngineFrameCount();
    NightPadActionEngineSetPaused(1);
    usleep(300000);
    unsigned long paused = NightPadActionEngineFrameCount();
    usleep(500000);
    unsigned long stillPaused = NightPadActionEngineFrameCount();
    const bool audioPaused = NightPadActionEngineAudioPaused() != 0;
    NightPadActionEngineSetPaused(0);
    usleep(500000);
    unsigned long resumed = NightPadActionEngineFrameCount();
    const bool audioResumed = NightPadActionEngineAudioPaused() == 0;
    bool ok = running > first && stillPaused == paused && resumed > stillPaused && audioPaused && audioResumed;
    printf("[lifecycle] pause frames: %lu -> %lu, paused %lu -> %lu, resumed %lu; audio %d/%d (%s)\n",
           first, running, paused, stillPaused, resumed, audioPaused, audioResumed, ok ? "PASS" : "FAIL");
    fflush(stdout);
    g_pauseOk.store(ok);
    g_pauseDone.store(true);
    return nullptr;
}
#endif

int main(int argc, char **argv) {
    mach_msg_type_number_t before = ThreadCount();
    mach_msg_type_number_t firstAfter = 0;
    bool ok = true;
    const char *cycleText = getenv("NIGHTPAD_LIFECYCLE_CYCLES");
    int cycles = cycleText != nullptr ? atoi(cycleText) : 3;
    if (cycles < 1)
        cycles = 1;
    const char *joinText = getenv("NIGHTPAD_JOIN_MS");
    unsigned joinTimeout = joinText != nullptr ? static_cast<unsigned>(atoi(joinText)) : 30000;
    const bool pauseTest = getenv("NIGHTPAD_PAUSE_TEST") != nullptr;
    ENGINE_SET_LAUNCH_CALLBACK(CaptureLaunch);
    for (int cycle = 0; cycle < cycles; ++cycle) {
        if (!ENGINE_START(argc, argv)) {
            fprintf(stderr, "action lifecycle: start failed on cycle %d\n", cycle + 1);
            return 1;
        }
#ifndef NIGHTPAD_DRIVING_LIFECYCLE
        if (cycle == 0 && pauseTest) {
            g_pauseCancel.store(false);
            g_pauseDone.store(false);
            g_pauseOk.store(false);
            pthread_t probe;
            pthread_create(&probe, nullptr, PauseProbe, nullptr);
            pthread_detach(probe);
        }
#endif
        const char *startPauseText = getenv("NIGHTPAD_START_PAUSE_MS");
        if (startPauseText != nullptr)
            usleep(static_cast<useconds_t>(atoi(startPauseText)) * 1000);
        mach_msg_type_number_t running = ThreadCount();
        pthread_t stopper;
        pthread_create(&stopper, nullptr, StopLater, nullptr);
        ENGINE_RUN_WINDOW();
        pthread_join(stopper, nullptr);
#ifndef NIGHTPAD_DRIVING_LIFECYCLE
        if (cycle == 0 && pauseTest) {
            for (int wait = 0; wait < 300 && !g_pauseDone.load(); ++wait)
                usleep(10000);
            ok = ok && g_pauseDone.load() && g_pauseOk.load();
        }
#endif
        ENGINE_CLOSE_WINDOW();
        int joined = ENGINE_JOIN(joinTimeout);
        sleep(2);
        mach_msg_type_number_t after = ThreadCount();
        if (cycle == 0)
            firstAfter = after;
        DumpThreads("after close");
        printf("action lifecycle cycle %d: threads before=%u running=%u after=%u joined=%s rss=%llu\n",
               cycle + 1, cycle == 0 ? before : firstAfter, running, after, joined ? "yes" : "no",
               ResidentBytes());
        ok = ok && joined == 1 && after <= firstAfter + 1;
        const char *pauseText = getenv("NIGHTPAD_CYCLE_PAUSE_MS");
        if (pauseText != nullptr)
            usleep(static_cast<useconds_t>(atoi(pauseText)) * 1000);
    }
    printf("action lifecycle: %s; baseline=%u settled=%u\n",
           ok ? "PASS" : "FAIL", before, firstAfter);
    return ok ? 0 : 2;
}

