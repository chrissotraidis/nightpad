#ifndef NIGHTPAD_TOUCH_POLICY_H_
#define NIGHTPAD_TOUCH_POLICY_H_

namespace nightpad {

// Touch controls belong to port 0. Only that port's physical owner may hide
// them: a second player's controller must not take the touch player's controls
// away. An explicit "always visible" choice wins over auto-hide.
bool ShouldHideTouchControls(bool touchPortControllerPresent, bool alwaysVisible, bool autoHideWithController);

}  // namespace nightpad

#endif  // NIGHTPAD_TOUCH_POLICY_H_
