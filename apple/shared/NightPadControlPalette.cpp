#include "NightPadControlPalette.h"

#include <algorithm>
#include <cmath>

namespace nightpad {
namespace {

float Linear(float channel) {
    channel = std::clamp(channel, 0.0f, 1.0f);
    return channel <= 0.04045f ? channel / 12.92f : std::pow((channel + 0.055f) / 1.055f, 2.4f);
}

}  // namespace

ControlColour ColourForControl(TouchControlId id) {
    switch (id) {
        case TouchControlId::A: return {0.10f, 0.45f, 0.18f};
        case TouchControlId::B: return {0.72f, 0.16f, 0.16f};
        case TouchControlId::X: return {0.10f, 0.28f, 0.72f};
        case TouchControlId::Y: return {0.55f, 0.42f, 0.04f};
        case TouchControlId::LeftStick:
        case TouchControlId::RightStick: return {0.30f, 0.30f, 0.30f};
        case TouchControlId::Dpad: return {0.36f, 0.36f, 0.36f};
        default: return {0.24f, 0.24f, 0.24f};
    }
}

float RelativeLuminance(const ControlColour &colour) {
    return 0.2126f * Linear(colour.red) + 0.7152f * Linear(colour.green) + 0.0722f * Linear(colour.blue);
}

float ContrastWithWhite(const ControlColour &colour) {
    return 1.05f / (RelativeLuminance(colour) + 0.05f);
}

}  // namespace nightpad
