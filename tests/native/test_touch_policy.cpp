#include "../../apple/shared/NightPadTouchPolicy.h"

#include <iostream>

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

int main() {
    using nightpad::ShouldHideTouchControls;
    Check(ShouldHideTouchControls(true, false, true), "player one controller hides touch");
    Check(!ShouldHideTouchControls(false, false, true), "no player one controller keeps touch");
    Check(!ShouldHideTouchControls(true, true, true), "always visible wins");
    Check(!ShouldHideTouchControls(true, false, false), "auto-hide off keeps touch");
    Check(!ShouldHideTouchControls(false, true, false), "nothing hides when idle");

    // The second player's controller is not port 0, so it must not hide the
    // touch player's overlay; the caller passes only the port-0 owner.
    Check(!ShouldHideTouchControls(false, false, true),
          "a player-two controller does not hide player one's touch controls");

    std::cout << (failures == 0 ? "touch policy: PASS" : "touch policy: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
