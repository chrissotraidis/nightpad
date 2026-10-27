#ifndef NIGHTPAD_ENGINE_BRIDGE_H_
#define NIGHTPAD_ENGINE_BRIDGE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    NIGHTPAD_ENGINE_ACTION = 0,
    NIGHTPAD_ENGINE_DRIVING = 1
} NightPadEngineId;

// Called on the requesting game thread after the launch page has been written. Return nonzero only when the
// coordinator owns the hand-over. The bridge then ends that game thread without spawning a child process.
typedef int (*NightPadLaunchRequestCallback)(NightPadEngineId engine, const char *executableName,
                                             const void *page, unsigned bytes);

void NightPadActionEngineSetLaunchRequestCallback(NightPadLaunchRequestCallback callback);
void NightPadDrivingEngineSetLaunchRequestCallback(NightPadLaunchRequestCallback callback);

unsigned NightPadActionEngineThread(void *unused);
unsigned NightPadDrivingEngineThread(void *unused);

#ifdef __cplusplus
}
#endif

#endif

