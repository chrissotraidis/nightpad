#ifndef NIGHTPAD_INPUT_H_
#define NIGHTPAD_INPUT_H_

#include <cstdint>

namespace nightpad {

// XInput's button bits: the shape the engine's HostPadState consumes.
enum XboxButton : uint32_t {
    kDpadUp = 0x0001,
    kDpadDown = 0x0002,
    kDpadLeft = 0x0004,
    kDpadRight = 0x0008,
    kStart = 0x0010,
    kBack = 0x0020,
    kLeftThumb = 0x0040,
    kRightThumb = 0x0080,
    kWhite = 0x0100,   // host LB
    kBlack = 0x0200,   // host RB
    kA = 0x1000,
    kB = 0x2000,
    kX = 0x4000,
    kY = 0x8000,
};

struct PadState {
    uint16_t buttons = 0;
    int16_t leftX = 0, leftY = 0, rightX = 0, rightY = 0;
    uint8_t leftTrigger = 0, rightTrigger = 0;
    bool connected = false;
    bool operator==(const PadState &other) const {
        return buttons == other.buttons && leftX == other.leftX && leftY == other.leftY && rightX == other.rightX &&
               rightY == other.rightY && leftTrigger == other.leftTrigger && rightTrigger == other.rightTrigger &&
               connected == other.connected;
    }
};

enum class InputSource { Touch = 0, Controller = 1 };

// Four Xbox ports. One physical controller owns at most one port; touch is the
// default owner of port 0. A newly acquired controller must release every held
// button before its input is accepted. Edges survive until consumed.
class InputMixer {
public:
    void Set(int port, InputSource source, const PadState &state);
    void Clear(int port, InputSource source);
    void ClearPort(int port);
    void ClearAll();
    // Native UI/background interruption: no buttons, triggers or sticks may
    // resurrect until that source has returned completely to neutral.
    void NeutralizeUntilRelease();

    // A controller joins or leaves. The port keeps its owner but both sources
    // release held/latched state until the source's buttons are all up.
    void SetControllerPresent(int port, bool present);
    bool ControllerPresent(int port) const { return controllerPresent_[port]; }

    // Applies dead zones/trigger thresholds and merges both sources for the port.
    PadState Consume(int port);

    static constexpr int kPorts = 4;
    static constexpr float kAxisDeadZone = 0.15f;
    static constexpr uint8_t kTriggerThreshold = 4;

private:
    static int index(InputSource source) { return source == InputSource::Touch ? 0 : 1; }
    static int16_t Axis(int16_t value);
    static uint8_t Trigger(uint8_t value);
    PadState states_[kPorts][2]{};
    uint16_t latched_[kPorts][2]{};
    bool requireRelease_[kPorts][2]{};
    bool requireNeutral_[kPorts][2]{};
    bool controllerPresent_[kPorts]{};
};

}  // namespace nightpad

#endif  // NIGHTPAD_INPUT_H_
