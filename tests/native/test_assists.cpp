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
static volatile int g_extras;

extern char menu_unlock_everything;   // action/game.cpp

static void Pause(bool paused) {
    NightPadActionEngineSetPaused(paused ? 1 : 0);
    if (paused)
        for (int i = 0; i < 300 && !NightPadActionEngineAudioPaused(); ++i)
            usleep(10000);
}

static void RunFrames(unsigned count) {
    const auto frame = NightPadActionEngineFrameCount();
    for (int i = 0; i < 300 && NightPadActionEngineFrameCount() < frame + count; ++i)
        usleep(10000);
}

// All Weapons and Unlock All Content are forced only while the app turns them
// on, and the game's own values come back when it turns them off.
static bool CheckExtras(void) {
    Pause(true);
    CheatInfo.AllWeapons = 0;
    menu_unlock_everything = 0;
    Pause(false);
    NightPadActionEngineSetAssistAllWeapons(1);
    NightPadActionEngineSetAssistUnlockAll(1);
    RunFrames(3);
    const bool on = CheatInfo.AllWeapons == 1 && menu_unlock_everything == 1;
    // A codename load that clears All Weapons does not win while the cheat is on.
    Pause(true);
    CheatInfo.AllWeapons = 0;
    Pause(false);
    RunFrames(3);
    const bool held = CheatInfo.AllWeapons == 1;
    NightPadActionEngineSetAssistAllWeapons(0);
    NightPadActionEngineSetAssistUnlockAll(0);
    RunFrames(3);
    const bool restored = CheatInfo.AllWeapons == 0 && menu_unlock_everything == 0;
    // A profile's own All Weapons survives when the app never turns it on.
    Pause(true);
    CheatInfo.AllWeapons = 1;
    Pause(false);
    RunFrames(3);
    const bool profileKept = CheatInfo.AllWeapons == 1;
    printf("assists extras: on=%d held=%d restored=%d profile=%d\n", on, held, restored, profileKept);
    return on && held && restored && profileKept;
}

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
    g_extras = CheckExtras();

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
    const int ok = g_booted && g_on && g_off && g_unownedLoad && g_defaultLoad && g_onLoad && g_offLoad && g_extras &&
                   joined;
    printf("assists: %s; frames=%lu booted=%d on=%d off=%d unowned=%d loads=%d/%d/%d extras=%d joined=%d\n",
           ok ? "PASS" : "FAIL",
           NightPadActionEngineFrameCount(), g_booted, g_on, g_off,
           g_unownedLoad, g_defaultLoad, g_onLoad, g_offLoad, g_extras, joined);
    return ok ? 0 : 2;
}
