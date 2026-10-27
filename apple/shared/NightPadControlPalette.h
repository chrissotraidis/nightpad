#ifndef NIGHTPAD_CONTROL_PALETTE_H_
#define NIGHTPAD_CONTROL_PALETTE_H_

#include "NightPadTouchLayout.h"

namespace nightpad {

struct ControlColour {
    float red = 1, green = 1, blue = 1;
};

// The Xbox face colours and the neutral controls, darkened enough for white
// labels to meet WCAG AA (contrast at least 4.5:1).
ControlColour ColourForControl(TouchControlId id);

// VoiceOver order: movement, shoulders, system, look, then face buttons.
int AccessibilityOrderForControl(TouchControlId id);

float RelativeLuminance(const ControlColour &colour);
// Contrast ratio against pure white text.
float ContrastWithWhite(const ControlColour &colour);

}  // namespace nightpad

#endif  // NIGHTPAD_CONTROL_PALETTE_H_
