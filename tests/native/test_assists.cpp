#include "../../apple/shared/NightPadEngineBridge.h"
#include "action/game.h"
#include "action/engine/LoadSave.h"

#include <array>
#include <cstring>
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

static volatile int g_booted;
static volatile int g_on;
static volatile int g_off;
static volatile int g_defaultLoad;
static volatile int g_onLoad;
static volatile int g_offLoad;
static volatile int g_unownedLoad;

// Load a real codename CHET block while the engine is paused, then let its
// normal loop reconcile it. No extra app exports or test-only engine seam.
static bool LoadCheats(unsigned loaded, unsigned expected) {
    NightPadActionEngineSetPaused(1);
    for (int i = 0; i < 300 && !NightPadActionEngineAudioPaused(); ++i)
        usleep(10000);
    if (!NightPadActionEngineAudioPaused()) return false;
    CheatInfo.Immortal = (loaded & 1u) != 0;
    CheatInfo.UnlimitedAmmo = (loaded & 2u) != 0;
    CheatInfo.AllWeapons = 1;
    ushort size = 0;
    uchar *encoded = LS_MakeCheats(0, 0, &size);
    std::array<uchar, 16> block{};
    if (size > block.size()) return false;
    std::memcpy(block.data(), encoded, size);
    CheatInfo.Immortal = CheatInfo.UnlimitedAmmo = CheatInfo.AllWeapons = 0;
    LS_LoadCheats(block.data(), 0);
    const bool loadedExactly = NightPadActionEngineAppliedAssists() == loaded &&
                               CheatInfo.AllWeapons == 1;
    const auto frame = NightPadActionEngineFrameCount();
    NightPadActionEngineSetPaused(0);
    for (int i = 0; i < 300 && NightPadActionEngineFrameCount() < frame + 2; ++i)
        usleep(10000);
    const bool ok = loadedExactly && NightPadActionEngineFrameCount() >= frame + 2 &&
                    NightPadActionEngineAppliedAssists() == expected && CheatInfo.AllWeapons == 1;
    printf("assists profile load: loaded=%u wanted=%u applied=%u %s\n", loaded, expected,
           NightPadActionEngineAppliedAssists(), ok ? "PASS" : "FAIL");
    return ok;
}

static void *ControlAssists(void *) {
    for (int i = 0; i < 900 && NightPadActionEngineFrameCount() == 0; ++i)
        usleep(100000);
    g_booted = NightPadActionEngineFrameCount() > 0;
    g_unownedLoad = LoadCheats(3u, 3u);
    NightPadActionEngineSetAssistImmortal(0);
    NightPadActionEngineSetAssistUnlimitedAmmo(0);
    g_defaultLoad = LoadCheats(3u, 0u);

    NightPadActionEngineSetAssistImmortal(1);
    NightPadActionEngineSetAssistUnlimitedAmmo(1);
    usleep(600000);
    g_on = NightPadActionEngineAppliedAssists() == 3u;
    g_onLoad = LoadCheats(0u, 3u);

    NightPadActionEngineSetAssistImmortal(0);
    NightPadActionEngineSetAssistUnlimitedAmmo(0);
    usleep(600000);
    g_off = NightPadActionEngineAppliedAssists() == 0u;
    g_offLoad = LoadCheats(3u, 0u);

    NightPadActionEngineRequestStop();
    return nullptr;
}

int main() {
    char program[] = "NightPad";
    char *argv[] = { program, nullptr };
    if (!NightPadActionEngineStart(1, argv)) {
        fprintf(stderr, "assists: action start failed\n");
        return 1;
    }
    pthread_t control;
    pthread_create(&control, nullptr, ControlAssists, nullptr);
    NightPadActionEngineRunWindow();
    pthread_join(control, nullptr);
    NightPadActionEngineCloseWindow();
    const int joined = NightPadActionEngineJoin(30000);
    const int ok = g_booted && g_on && g_off && g_unownedLoad && g_defaultLoad && g_onLoad && g_offLoad && joined;
    printf("assists: %s; frames=%lu booted=%d on=%d off=%d unowned=%d loads=%d/%d/%d joined=%d\n", ok ? "PASS" : "FAIL",
           NightPadActionEngineFrameCount(), g_booted, g_on, g_off,
           g_unownedLoad, g_defaultLoad, g_onLoad, g_offLoad, joined);
    return ok ? 0 : 2;
}
