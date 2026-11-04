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
    // The layout index of the control this finger started on, or -1. A finger
    // that starts on a stick, the D-pad or a trigger keeps driving it wherever it
    // moves, so a thumb that drifts past the edge does not drop movement or aim.
    int control = -1;
    // Where the finger landed (normalized). Sticks measure deflection from here,
    // so landing off-centre does not jerk the stick; -1 uses the stick's centre.
    float originX = -1, originY = -1;
};

// The layout index of the visible control under a point, or -1.
int TouchControlAt(const TouchLayout &layout, float x, float y);
// The layout index of the control a finger drives under the capture rules
// above (for drawing it pressed), or -1.
int TouchOwnerFor(const TouchLayout &layout, const TouchPoint &point);

// Turns every live finger into the Xbox pad the authored layout describes:
// sticks use the offset from their centre (Y up positive), the D-pad is
// eight-way with a centre dead zone, face/shoulder/system buttons are digital,
// and LT/RT ramp from a light touch at the top edge to full travel at the
// bottom. When two fingers share a control the newest (highest id) wins, and a
// finger only reaches a visible control.
PadState TouchPadState(const TouchLayout &layout, const TouchPoint *points, std::size_t count);

}  // namespace nightpad

#endif  // NIGHTPAD_TOUCH_INPUT_H_
