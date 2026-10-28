#ifndef NIGHTPAD_TOUCH_LAYOUT_H_
#define NIGHTPAD_TOUCH_LAYOUT_H_

#include <filesystem>
#include <string>
#include <vector>

namespace nightpad {

enum class TouchControlId {
    LeftStick,
    RightStick,
    Dpad,
    A,
    B,
    X,
    Y,
    LeftTrigger,
    RightTrigger,
    White,
    Black,
    Start,
    Back,
};

enum class TouchDeviceClass { Phone, Tablet };

struct TouchControl {
    TouchControlId id;
    float x = 0, y = 0, width = 0, height = 0;   // normalized safe-area rectangle
    float opacity = 0.7f;
    bool visible = true;
};

struct TouchLayout {
    // 3: the GalaxyPad-derived controller layout. Older files load as unsupported and fall back to the defaults.
    int version = 3;
    TouchDeviceClass device = TouchDeviceClass::Phone;
    std::vector<TouchControl> controls;

    static TouchLayout Defaults(TouchDeviceClass device);
    void Reset();

    // Keeps every control inside the safe area and no smaller than minPoints in
    // either axis. Opacity is clamped to [0.2, 1].
    void Clamp(float viewWidth, float viewHeight, float minPoints = 44.0f);

    bool Save(const std::filesystem::path &path, std::string *error) const;
    bool Load(const std::filesystem::path &path, std::string *error);
};

const char *TouchControlName(TouchControlId id);
const char *TouchDeviceName(TouchDeviceClass device);

}  // namespace nightpad

#endif  // NIGHTPAD_TOUCH_LAYOUT_H_
