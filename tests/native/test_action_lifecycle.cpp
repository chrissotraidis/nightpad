#include "../../apple/shared/NightPadEngineBridge.h"

#include <mach/mach.h>
#include <mach/thread_info.h>
#include <dlfcn.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

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

static void *StopLater(void *) {
    sleep(6);
    ENGINE_REQUEST_STOP();
    return nullptr;
}

static int CaptureLaunch(NightPadEngineId, const char *image, const void *, unsigned bytes) {
    printf("[lifecycle] in-process launch request: %s (%u bytes)\n", image, bytes);
    return 1;
}

int main(int argc, char **argv) {
    mach_msg_type_number_t before = ThreadCount();
    mach_msg_type_number_t firstAfter = 0;
    bool ok = true;
    const char *cycleText = getenv("NIGHTPAD_LIFECYCLE_CYCLES");
    int cycles = cycleText != nullptr ? atoi(cycleText) : 3;
    if (cycles < 1)
        cycles = 1;
    ENGINE_SET_LAUNCH_CALLBACK(CaptureLaunch);
    for (int cycle = 0; cycle < cycles; ++cycle) {
        if (!ENGINE_START(argc, argv)) {
            fprintf(stderr, "action lifecycle: start failed on cycle %d\n", cycle + 1);
            return 1;
        }
        mach_msg_type_number_t running = ThreadCount();
        pthread_t stopper;
        pthread_create(&stopper, nullptr, StopLater, nullptr);
        ENGINE_RUN_WINDOW();
        pthread_join(stopper, nullptr);
        int joined = ENGINE_JOIN(30000);
        ENGINE_CLOSE_WINDOW();
        sleep(2);
        mach_msg_type_number_t after = ThreadCount();
        if (cycle == 0)
            firstAfter = after;
        DumpThreads("after close");
        printf("action lifecycle cycle %d: threads before=%u running=%u after=%u joined=%s\n",
               cycle + 1, cycle == 0 ? before : firstAfter, running, after, joined ? "yes" : "no");
        ok = ok && joined == 1 && after <= firstAfter + 1;
    }
    printf("action lifecycle: %s; baseline=%u settled=%u\n",
           ok ? "PASS" : "FAIL", before, firstAfter);
    return ok ? 0 : 2;
}

