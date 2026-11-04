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

// Controls that sit together on a real pad move and resize as one item, so the
// diamond and the paired buttons keep their shape and matching sizes.
enum class TouchGroup { None, Face, Shoulders, System };

struct TouchControl {
    TouchControlId id;
    float x = 0, y = 0, width = 0, height = 0;   // normalized safe-area rectangle
    // Kept for file compatibility. The overlay uses one app-wide opacity.
    float opacity = 0.7f;
    bool visible = true;
};

struct TouchLayout {
    // File format, independent of default geometry. Existing custom layouts
    // remain valid when the authored defaults change; Reset adopts new defaults.
    int version = 3;
    TouchDeviceClass device = TouchDeviceClass::Phone;
    std::vector<TouchControl> controls;

    static TouchLayout Defaults(TouchDeviceClass device);
    void Reset();

    // Keeps every control inside the safe area and no smaller than minPoints in
    // either axis. Opacity is clamped to [0.2, 1].
    void Clamp(float viewWidth, float viewHeight, float minPoints = 44.0f);

    // The same resolved rectangles drive drawing, hit testing and editing.
    // Round controls stay square in points, including on a different aspect.
    TouchLayout ForCanvas(float viewWidth, float viewHeight, float minPoints = 44.0f) const;

    // Editing works on items: a single control, or its whole group. Moves keep
    // the item inside the canvas. Scaling is about the item's centre, gives a
    // group's members one common size, and keeps every member at least
    // minPoints on the given canvas.
    void MoveItem(TouchControlId id, float dx, float dy);
    void ScaleItem(TouchControlId id, float factor, float viewWidth, float viewHeight, float minPoints = 44.0f);
    // Item size relative to this device's default (1 = default size).
    float ItemScale(TouchControlId id) const;
    void SetItemVisible(TouchControlId id, bool visible);
    bool ItemVisible(TouchControlId id) const;

    bool Save(const std::filesystem::path &path, std::string *error) const;
    bool Load(const std::filesystem::path &path, std::string *error);
};

const char *TouchControlName(TouchControlId id);
const char *TouchDeviceName(TouchDeviceClass device);
TouchGroup TouchGroupFor(TouchControlId id);
// True for every control in the same item as id (including id itself).
bool SameTouchItem(TouchControlId a, TouchControlId b);

}  // namespace nightpad

#endif  // NIGHTPAD_TOUCH_LAYOUT_H_
