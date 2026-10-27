#include "../../apple/shared/NightPadEngineBridge.h"

#include <mach/mach.h>
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

static void *StopLater(void *) {
    sleep(10);
    NightPadActionEngineRequestStop();
    return nullptr;
}

int main(int argc, char **argv) {
    mach_msg_type_number_t before = ThreadCount();
    if (!NightPadActionEngineStart(argc, argv)) {
        fprintf(stderr, "action lifecycle: start failed\n");
        return 1;
    }
    mach_msg_type_number_t running = ThreadCount();

    pthread_t stopper;
    pthread_create(&stopper, nullptr, StopLater, nullptr);
    NightPadActionEngineRunWindow();
    pthread_join(stopper, nullptr);
    int joined = NightPadActionEngineJoin(30000);
    NightPadActionEngineCloseWindow();
    sleep(2);   // Cocoa and SDL worker threads retire asynchronously
    mach_msg_type_number_t after = ThreadCount();
    bool ok = joined == 1 && after <= before + 1;
    printf("action lifecycle: %s; threads before=%u running=%u after=%u joined=%s\n",
           ok ? "PASS" : "FAIL", before, running, after, joined ? "yes" : "no");
    return ok ? 0 : 2;
}

