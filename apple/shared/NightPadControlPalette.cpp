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
        case TouchControlId::A: return {0.10f, 0.62f, 0.30f};
        case TouchControlId::B: return {0.92f, 0.16f, 0.18f};
        case TouchControlId::X: return {0.10f, 0.48f, 0.95f};
        case TouchControlId::Y: return {0.95f, 0.76f, 0.08f};
        case TouchControlId::LeftStick:
        case TouchControlId::RightStick: return {0.30f, 0.30f, 0.30f};
        case TouchControlId::Dpad: return {0.36f, 0.36f, 0.36f};
        case TouchControlId::White: return {0.92f, 0.92f, 0.92f};
        default: return {0.24f, 0.24f, 0.24f};
    }
}

float RelativeLuminance(const ControlColour &colour) {
    return 0.2126f * Linear(colour.red) + 0.7152f * Linear(colour.green) + 0.0722f * Linear(colour.blue);
}

float ContrastWithWhite(const ControlColour &colour) {
    return 1.05f / (RelativeLuminance(colour) + 0.05f);
}

float ContrastWithBlack(const ControlColour &colour) {
    return (RelativeLuminance(colour) + 0.05f) / 0.05f;
}

bool UsesDarkLabel(TouchControlId id) {
    return id == TouchControlId::A || id == TouchControlId::B || id == TouchControlId::X ||
           id == TouchControlId::Y || id == TouchControlId::White;
}

int AccessibilityOrderForControl(TouchControlId id) {
    switch (id) {
        case TouchControlId::LeftStick: return 0;
        case TouchControlId::Dpad: return 1;
        case TouchControlId::LeftTrigger: return 2;
        case TouchControlId::White: return 3;
        case TouchControlId::Back: return 4;
        case TouchControlId::Start: return 5;
        case TouchControlId::Black: return 6;
        case TouchControlId::RightTrigger: return 7;
        case TouchControlId::RightStick: return 8;
        case TouchControlId::A: return 9;
        case TouchControlId::B: return 10;
        case TouchControlId::X: return 11;
        case TouchControlId::Y: return 12;
    }
    return 13;
}

}  // namespace nightpad
