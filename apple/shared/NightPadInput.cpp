#include "NightPadInput.h"

#include <algorithm>
#include <cmath>

namespace nightpad {

int16_t InputMixer::Axis(int16_t value) {
    const float normalized = float(value) / 32767.0f;
    if (!std::isfinite(normalized) || std::fabs(normalized) < kAxisDeadZone)
        return 0;
    const float clamped = std::clamp(normalized, -1.0f, 1.0f);
    return static_cast<int16_t>(std::lround(clamped * 32767.0f));
}

uint8_t InputMixer::Trigger(uint8_t value) {
    return value < kTriggerThreshold ? 0 : value;
}

void InputMixer::Set(int port, InputSource source, const PadState &raw) {
    if (port < 0 || port >= kPorts)
        return;
    const int which = index(source);
    PadState state = raw;
    state.leftX = Axis(raw.leftX);
    state.leftY = Axis(raw.leftY);
    state.rightX = Axis(raw.rightX);
    state.rightY = Axis(raw.rightY);
    state.leftTrigger = Trigger(raw.leftTrigger);
    state.rightTrigger = Trigger(raw.rightTrigger);
    if (requireRelease_[port][which]) {
        if (state.buttons == 0)
            requireRelease_[port][which] = false;
        state.buttons = 0;
    }
    latched_[port][which] |= state.buttons & ~states_[port][which].buttons;
    states_[port][which] = state;
}

void InputMixer::Clear(int port, InputSource source) {
    if (port < 0 || port >= kPorts)
        return;
    const int which = index(source);
    states_[port][which] = {};
    latched_[port][which] = 0;
    requireRelease_[port][which] = false;
}

void InputMixer::ClearPort(int port) {
    if (port < 0 || port >= kPorts)
        return;
    Clear(port, InputSource::Touch);
    Clear(port, InputSource::Controller);
    controllerPresent_[port] = false;
}

void InputMixer::ClearAll() {
    for (int port = 0; port < kPorts; ++port)
        ClearPort(port);
}

void InputMixer::SetControllerPresent(int port, bool present) {
    if (port < 0 || port >= kPorts)
        return;
    if (controllerPresent_[port] == present)
        return;
    controllerPresent_[port] = present;
    states_[port][index(InputSource::Controller)] = {};
    latched_[port][index(InputSource::Controller)] = 0;
    latched_[port][index(InputSource::Touch)] = 0;
    requireRelease_[port][index(InputSource::Controller)] = present;
}

PadState InputMixer::Consume(int port) {
    PadState out;
    if (port < 0 || port >= kPorts)
        return out;
    const PadState &touch = states_[port][0];
    const PadState &controller = states_[port][1];
    out.buttons = uint16_t(touch.buttons | controller.buttons | latched_[port][0] | latched_[port][1]);
    out.leftX = std::abs(controller.leftX) > std::abs(touch.leftX) ? controller.leftX : touch.leftX;
    out.leftY = std::abs(controller.leftY) > std::abs(touch.leftY) ? controller.leftY : touch.leftY;
    out.rightX = std::abs(controller.rightX) > std::abs(touch.rightX) ? controller.rightX : touch.rightX;
    out.rightY = std::abs(controller.rightY) > std::abs(touch.rightY) ? controller.rightY : touch.rightY;
    out.leftTrigger = std::max(touch.leftTrigger, controller.leftTrigger);
    out.rightTrigger = std::max(touch.rightTrigger, controller.rightTrigger);
    out.connected = touch.connected || controller.connected;
    latched_[port][0] = latched_[port][1] = 0;
    return out;
}

}  // namespace nightpad
