#include "../../apple/shared/NightPadBackgroundPolicy.h"

#include <iostream>

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

int main() {
    using nightpad::ShouldPauseForBackground;
    using nightpad::ShouldResumeAfterBackground;

    Check(ShouldPauseForBackground(true, false, false), "playing app pauses on background");
    Check(!ShouldPauseForBackground(false, false, false), "stopped app does nothing");
    Check(!ShouldPauseForBackground(true, true, false), "native UI already holds it");
    Check(!ShouldPauseForBackground(true, false, true), "player pause stays a pause");

    Check(ShouldResumeAfterBackground(true, true, true), "background pause resumes");
    Check(!ShouldResumeAfterBackground(false, true, true), "manual pause does not resume");
    Check(!ShouldResumeAfterBackground(true, false, true), "a stopped engine does not resume");
    Check(!ShouldResumeAfterBackground(true, true, false), "nothing to resume");

    nightpad::NativeUiPauseState state{true, false, false, true, 0};
    auto held = [&] { return nightpad::ShouldHoldForNativeUI(state); };
    Check(!held(), "active gameplay is released");
    state.menuVisible = true;
    Check(held(), "opening root menu holds gameplay");
    state.surfaceVisible = true;
    state.menuVisible = false;
    Check(held(), "menu-to-sheet handoff retains the hold");
    state.applicationActive = false;
    state.surfaceVisible = false;
    Check(held(), "dismissing a sheet while inactive cannot resume");
    state.applicationActive = true;
    Check(!held(), "becoming active releases the last hold");
    state.menuVisible = true;
    state.alerts = 2;
    state.menuVisible = false;
    Check(held(), "menu-to-alert handoff retains the hold");
    --state.alerts;
    Check(held(), "closing one of two alerts retains the hold");
    --state.alerts;
    Check(!held(), "closing the last alert releases gameplay");
    state.menuVisible = true;
    state.engineRunning = false;
    Check(!held(), "stopping discards the engine hold even with menu visible");
    state.engineRunning = true;
    Check(held(), "starting under an open menu acquires a hold");

    std::cout << (failures == 0 ? "background policy: PASS" : "background policy: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
