#ifndef NIGHTPAD_TOUCH_INPUT_H_
#define NIGHTPAD_TOUCH_INPUT_H_

#include "NightPadInput.h"
#include "NightPadTouchLayout.h"

#include <cstddef>

namespace nightpad {

// A live finger inside the touch canvas. Coordinates are normalized 0..1 with
// the origin at the top-left of the safe-area canvas, so the same samples work
// for any device size.
struct TouchPoint {
    int id = 0;
    float x = 0, y = 0;
};

// Turns every live finger into the Xbox pad the authored layout describes:
// sticks use the offset from their centre (Y up positive), the D-pad is
// eight-way with a centre dead zone, face/shoulder/system buttons are digital,
// and LT/RT ramp from a light touch at the top edge to full travel at the
// bottom. When two fingers share a control the newest (highest id) wins, and a
// finger only reaches a visible control.
PadState TouchPadState(const TouchLayout &layout, const TouchPoint *points, std::size_t count);

}  // namespace nightpad

#endif  // NIGHTPAD_TOUCH_INPUT_H_
