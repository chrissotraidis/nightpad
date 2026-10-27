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

    std::cout << (failures == 0 ? "background policy: PASS" : "background policy: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
