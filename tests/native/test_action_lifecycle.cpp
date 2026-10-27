#include "../../apple/shared/NightPadEngineBridge.h"

#include <mach/mach.h>
#include <mach/thread_info.h>
#include <dlfcn.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

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
    NightPadActionEngineRequestStop();
    return nullptr;
}

int main(int argc, char **argv) {
    mach_msg_type_number_t before = ThreadCount();
    mach_msg_type_number_t firstAfter = 0;
    bool ok = true;
    for (int cycle = 0; cycle < 3; ++cycle) {
        if (!NightPadActionEngineStart(argc, argv)) {
            fprintf(stderr, "action lifecycle: start failed on cycle %d\n", cycle + 1);
            return 1;
        }
        mach_msg_type_number_t running = ThreadCount();
        pthread_t stopper;
        pthread_create(&stopper, nullptr, StopLater, nullptr);
        NightPadActionEngineRunWindow();
        pthread_join(stopper, nullptr);
        int joined = NightPadActionEngineJoin(30000);
        NightPadActionEngineCloseWindow();
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

