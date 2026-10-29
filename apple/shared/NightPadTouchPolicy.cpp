#include "NightPadTouchPolicy.h"

namespace nightpad {

bool ShouldHideTouchControls(bool touchPortControllerPresent, bool alwaysVisible, bool autoHideWithController) {
    if (alwaysVisible)
        return false;
    if (!autoHideWithController)
        return false;
    return touchPortControllerPresent;
}

}  // namespace nightpad
