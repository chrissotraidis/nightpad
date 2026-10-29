#include "NightPadTouchInput.h"

#include <algorithm>
#include <cmath>
#include <vector>

namespace nightpad {
namespace {

constexpr float kStickDeadZone = 0.12f;
constexpr float kDpadDeadZone = 0.22f;
constexpr float kTriggerTouchFloor = 24.0f;
constexpr float kTriggerRampStart = 0.10f;

bool Contains(const TouchControl &control, const TouchPoint &point) {
    return point.x >= control.x && point.x <= control.x + control.width && point.y >= control.y &&
           point.y <= control.y + control.height;
}

uint16_t BitFor(TouchControlId id) {
    switch (id) {
        case TouchControlId::Dpad: return 0;  // handled as four directions
        case TouchControlId::A: return kA;
        case TouchControlId::B: return kB;
        case TouchControlId::X: return kX;
        case TouchControlId::Y: return kY;
        case TouchControlId::White: return kWhite;
        case TouchControlId::Black: return kBlack;
        case TouchControlId::Start: return kStart;
        case TouchControlId::Back: return kBack;
        case TouchControlId::LeftTrigger:
        case TouchControlId::RightTrigger:
        case TouchControlId::LeftStick:
        case TouchControlId::RightStick: return 0;
    }
    return 0;
}

int16_t AxisFrom(float value) {
    const float clamped = std::clamp(value, -1.0f, 1.0f);
    return static_cast<int16_t>(std::lround(clamped * 32767.0f));
}

void ApplyStick(const TouchControl &control, const TouchPoint &point, int16_t *x, int16_t *y) {
    if (control.width <= 0 || control.height <= 0)
        return;
    const float halfWidth = control.width * 0.5f;
    const float halfHeight = control.height * 0.5f;
    float dx = (point.x - (control.x + halfWidth)) / halfWidth;
    float dy = (point.y - (control.y + halfHeight)) / halfHeight;
    const float length = std::hypot(dx, dy);
    if (length > 1.0f) {
        dx /= length;
        dy /= length;
    }
    if (std::hypot(dx, dy) < kStickDeadZone)
        dx = dy = 0;
    *x = AxisFrom(dx);
    *y = AxisFrom(-dy);  // XInput's Y is up-positive; UIKit's is down-positive.
}

uint16_t ApplyDpad(const TouchControl &control, const TouchPoint &point) {
    if (control.width <= 0 || control.height <= 0)
        return 0;
    const float dx = (point.x - (control.x + control.width * 0.5f)) / (control.width * 0.5f);
    const float dy = (point.y - (control.y + control.height * 0.5f)) / (control.height * 0.5f);
    uint16_t bits = 0;
    if (std::fabs(dy) > kDpadDeadZone)
        bits |= dy < 0 ? kDpadUp : kDpadDown;
    if (std::fabs(dx) > kDpadDeadZone)
        bits |= dx < 0 ? kDpadLeft : kDpadRight;
    return bits;
}

uint8_t ApplyTrigger(const TouchControl &control, const TouchPoint &point) {
    if (control.height <= 0)
        return 0;
    const float depth = (point.y - control.y) / control.height;
    const float ramp = std::clamp((depth - kTriggerRampStart) / (1.0f - kTriggerRampStart), 0.0f, 1.0f);
    return static_cast<uint8_t>(std::lround(kTriggerTouchFloor + ramp * (255.0f - kTriggerTouchFloor)));
}

}  // namespace

PadState TouchPadState(const TouchLayout &layout, const TouchPoint *points, std::size_t count) {
    PadState pad;
    pad.connected = true;
    if (points == nullptr)
        return pad;

    // Newest finger wins when two share a control, matching what the player
    // sees when a thumb slides back on without lifting cleanly.
    std::vector<const TouchPoint *> owner(layout.controls.size(), nullptr);
    for (std::size_t i = 0; i < count; ++i) {
        for (std::size_t c = 0; c < layout.controls.size(); ++c) {
            const TouchControl &control = layout.controls[c];
            if (!control.visible || !Contains(control, points[i]))
                continue;
            if (owner[c] == nullptr || points[i].id >= owner[c]->id)
                owner[c] = &points[i];
        }
    }

    for (std::size_t c = 0; c < layout.controls.size(); ++c) {
        const TouchControl &control = layout.controls[c];
        const TouchPoint *point = owner[c];
        if (point == nullptr)
            continue;
        switch (control.id) {
            case TouchControlId::LeftStick: ApplyStick(control, *point, &pad.leftX, &pad.leftY); break;
            case TouchControlId::RightStick: ApplyStick(control, *point, &pad.rightX, &pad.rightY); break;
            case TouchControlId::Dpad: pad.buttons |= ApplyDpad(control, *point); break;
            case TouchControlId::LeftTrigger: pad.leftTrigger = ApplyTrigger(control, *point); break;
            case TouchControlId::RightTrigger: pad.rightTrigger = ApplyTrigger(control, *point); break;
            default: pad.buttons |= BitFor(control.id); break;
        }
    }
    return pad;
}

}  // namespace nightpad
