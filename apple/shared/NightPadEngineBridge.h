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

// Ask the active game loop to leave at its next safe frame boundary. The engine's normal cleanup then runs.
void NightPadActionEngineRequestStop(void);
void NightPadActionEngineSetPaused(int paused);
void NightPadActionEngineSetInputSuspended(int suspended);
// The app owns the pads: publish each port's state (connected = 0 removes it) before the engine reads input.
// Rumble requests are handed to the shell so they reach the controller the player actually holds.
typedef void (*NightPadRumbleHandler)(int port, unsigned leftMotor, unsigned rightMotor);
void NightPadActionEngineSetHostPadsEnabled(int enabled);
void NightPadActionEngineSetHostPad(int port, unsigned buttons, int leftX, int leftY, int rightX, int rightY,
                                    unsigned leftTrigger, unsigned rightTrigger, int connected);
void NightPadActionEngineSetRumbleHandler(NightPadRumbleHandler handler);
unsigned long NightPadActionEngineFrameCount(void);
void NightPadDrivingEngineRequestStop(void);
int NightPadActionEngineStart(int argc, char **argv);
void NightPadActionEngineRunWindow(void);
int NightPadActionEnginePollWindow(void);
int NightPadActionEngineJoin(unsigned timeoutMilliseconds);
void NightPadActionEngineCloseWindow(void);
// Test/coordinator hook: after this many main-loop frames, use the game's own psiLaunchDriving seam.
void NightPadActionEngineTriggerDrivingAfter(unsigned frames);
int NightPadDrivingEngineStart(int argc, char **argv);
void NightPadDrivingEngineRunWindow(void);
int NightPadDrivingEngineJoin(unsigned timeoutMilliseconds);
void NightPadDrivingEngineCloseWindow(void);

unsigned NightPadActionEngineThread(void *unused);
unsigned NightPadDrivingEngineThread(void *unused);

#ifdef __cplusplus
}
#endif

#endif

