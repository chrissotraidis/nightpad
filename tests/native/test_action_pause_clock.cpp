#include "../../apple/shared/NightPadEngineBridge.h"
#include "action/game.h"
#include "action/game/mp/multiplayer.h"

#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

extern uint32_t switch_MP4EVER;
static bool passed = true;

static bool Pause() {
    NightPadActionEngineSetPaused(1);
    for (int i = 0; i < 500 && !NightPadActionEngineAudioPaused(); ++i)
        usleep(10000);
    return NightPadActionEngineAudioPaused() != 0;
}

static void *Probe(void *argument) {
    const int cycle = static_cast<int>(reinterpret_cast<intptr_t>(argument));
    for (int i = 0; i < 2000 && NightPadActionEngineFrameCount() < 3; ++i)
        usleep(10000);
    if (NightPadActionEngineFrameCount() < 3 || !Pause()) {
        passed = false;
        NightPadActionEngineRequestStop();
        return nullptr;
    }

    // The game thread is held. Exercise the real multiplayer clock consumer
    // without a level/sprite: an unlimited match still accumulates play time.
    const auto settings = MPSettings;
    const auto match = MPGame;
    const auto gamePause = GameState.SomeAlternatePauseState;
    const auto forever = switch_MP4EVER;
    MPSettings.isMultiplayer = 0;
    MPSettings.GameMode = GM_ARENA;
    MPSettings.MaxDuration = MPSettings.MaxPoints = -1;
    MPGame = {};
    MPGame.lastTimePaused = -1;
    GameState.SomeAlternatePauseState = 0;
    switch_MP4EVER = 0;
    MP_CheckForEndCondition();
    const auto before = psiGetTimeIn100ths();
    const auto frames = NightPadActionEngineFrameCount();
    const double wall = timestamp();
    usleep(650000);
    // Repeated ownership requests must not reset the pause's origin.
    NightPadActionEngineSetPaused(1);
    usleep(150000);
    MP_CheckForEndCondition();
    const auto held = psiGetTimeIn100ths();
    const float matchElapsed = MPGame.TimeUnpaused;
    const bool frozen = held == before && matchElapsed < 0.011f &&
                        NightPadActionEngineFrameCount() == frames && timestamp() - wall >= 750;
    MPSettings = settings;
    MPGame = match;
    GameState.SomeAlternatePauseState = gamePause;
    switch_MP4EVER = forever;

    NightPadActionEngineSetPaused(0);
    usleep(300000);
    const bool resumed = Pause();
    const auto after = psiGetTimeIn100ths();
    const auto elapsed = after - held;
    const bool running = resumed && elapsed >= 20 && elapsed < 65 &&
                         NightPadActionEngineFrameCount() > frames;
    printf("pause clock cycle %d: held=%llu->%llu match=%.3f resume=%llu frames=%lu->%lu %s\n",
           cycle, before, held, matchElapsed, elapsed, frames,
           NightPadActionEngineFrameCount(), frozen && running ? "PASS" : "FAIL");
    passed = passed && frozen && running;
    // Stop while held; the next boot must not inherit a frozen clock.
    NightPadActionEngineRequestStop();
    return nullptr;
}

int main() {
    char name[] = "NightPad";
    char *argv[] = {name, nullptr};
    for (int cycle = 1; cycle <= 2; ++cycle) {
        if (!NightPadActionEngineStart(1, argv)) return 1;
        pthread_t probe;
        pthread_create(&probe, nullptr, Probe, reinterpret_cast<void *>(static_cast<intptr_t>(cycle)));
        NightPadActionEngineRunWindow();
        pthread_join(probe, nullptr);
        NightPadActionEngineCloseWindow();
        passed = NightPadActionEngineJoin(30000) && passed;
    }
    printf("action pause clock: %s\n", passed ? "PASS" : "FAIL");
    return passed ? 0 : 2;
}
