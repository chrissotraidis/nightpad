#include "NightPadTouchLayout.h"

#include <algorithm>
#include <fstream>
#include <sstream>
#include <system_error>
#include <utility>

namespace nightpad {
namespace fs = std::filesystem;

namespace {

struct DefaultControl {
    TouchControlId id;
    float x, y, w, h;
};

// Landscape phone geometry, following SunPad's controller arrangement: a round
// move stick in the lower-left corner with the D-pad beside it, a camera stick
// in the lower-right corner, a diamond face cluster above it, shoulders at the
// top corners, White/Black down the right edge, and Start/Back at the top left.
// Sizes are the SunPad point sizes against an 850x360 safe area.
constexpr DefaultControl kPhone[] = {
    { TouchControlId::LeftStick, 0.0594f, 0.5533f, 0.1412f, 0.3333f },
    { TouchControlId::RightStick, 0.8286f, 0.6100f, 0.1129f, 0.2667f },
    { TouchControlId::Dpad, 0.2612f, 0.5611f, 0.1176f, 0.2778f },
    { TouchControlId::Y, 0.7730f, 0.1500f, 0.0541f, 0.1375f },
    { TouchControlId::X, 0.6979f, 0.2950f, 0.0541f, 0.1375f },
    { TouchControlId::B, 0.8432f, 0.3100f, 0.0635f, 0.1375f },
    { TouchControlId::A, 0.7624f, 0.4550f, 0.0753f, 0.1375f },
    { TouchControlId::LeftTrigger, 0.0359f, 0.1650f, 0.1082f, 0.1375f },
    { TouchControlId::RightTrigger, 0.8559f, 0.1650f, 0.1082f, 0.1375f },
    { TouchControlId::White, 0.9391f, 0.3150f, 0.0518f, 0.1375f },
    { TouchControlId::Black, 0.9391f, 0.4600f, 0.0518f, 0.1375f },
    { TouchControlId::Start, 0.0429f, 0.0200f, 0.0941f, 0.1375f },
    { TouchControlId::Back, 0.1473f, 0.0200f, 0.0753f, 0.1375f },
};

// Tablet geometry: the same arrangement; the safe area is larger, so the
// normalized controls stay proportional.
constexpr DefaultControl kTablet[] = {
    { TouchControlId::LeftStick, 0.0650f, 0.5666f, 0.1299f, 0.3066f },
    { TouchControlId::RightStick, 0.8331f, 0.6207f, 0.1039f, 0.2454f },
    { TouchControlId::Dpad, 0.2659f, 0.5722f, 0.1082f, 0.2556f },
    { TouchControlId::Y, 0.7752f, 0.1555f, 0.0498f, 0.1265f },
    { TouchControlId::X, 0.7001f, 0.3005f, 0.0498f, 0.1265f },
    { TouchControlId::B, 0.8458f, 0.3155f, 0.0584f, 0.1265f },
    { TouchControlId::A, 0.7654f, 0.4605f, 0.0693f, 0.1265f },
    { TouchControlId::LeftTrigger, 0.0402f, 0.1705f, 0.0995f, 0.1265f },
    { TouchControlId::RightTrigger, 0.8602f, 0.1705f, 0.0995f, 0.1265f },
    { TouchControlId::White, 0.9412f, 0.3205f, 0.0477f, 0.1265f },
    { TouchControlId::Black, 0.9412f, 0.4655f, 0.0477f, 0.1265f },
    { TouchControlId::Start, 0.0467f, 0.0255f, 0.0866f, 0.1265f },
    { TouchControlId::Back, 0.1503f, 0.0255f, 0.0693f, 0.1265f },
};

TouchControlId ParseId(const std::string &name) {
    for (int i = 0; i <= int(TouchControlId::Back); ++i) {
        TouchControlId id = TouchControlId(i);
        if (name == TouchControlName(id))
            return id;
    }
    return TouchControlId::Back;
}

bool KnownId(const std::string &name) {
    for (int i = 0; i <= int(TouchControlId::Back); ++i)
        if (name == TouchControlName(TouchControlId(i)))
            return true;
    return false;
}

}  // namespace

const char *TouchControlName(TouchControlId id) {
    switch (id) {
        case TouchControlId::LeftStick: return "left_stick";
        case TouchControlId::RightStick: return "right_stick";
        case TouchControlId::Dpad: return "dpad";
        case TouchControlId::A: return "a";
        case TouchControlId::B: return "b";
        case TouchControlId::X: return "x";
        case TouchControlId::Y: return "y";
        case TouchControlId::LeftTrigger: return "lt";
        case TouchControlId::RightTrigger: return "rt";
        case TouchControlId::White: return "white";
        case TouchControlId::Black: return "black";
        case TouchControlId::Start: return "start";
        case TouchControlId::Back: return "back";
    }
    return "back";
}

const char *TouchDeviceName(TouchDeviceClass device) {
    return device == TouchDeviceClass::Tablet ? "tablet" : "phone";
}

TouchLayout TouchLayout::Defaults(TouchDeviceClass device) {
    TouchLayout layout;
    layout.device = device;
    const auto *controls = device == TouchDeviceClass::Tablet ? kTablet : kPhone;
    const size_t count = device == TouchDeviceClass::Tablet ? sizeof(kTablet) / sizeof(kTablet[0])
                                                            : sizeof(kPhone) / sizeof(kPhone[0]);
    for (size_t i = 0; i < count; ++i)
        layout.controls.push_back({controls[i].id, controls[i].x, controls[i].y, controls[i].w, controls[i].h, 0.7f, true});
    return layout;
}

void TouchLayout::Reset() {
    *this = Defaults(device);
}

void TouchLayout::Clamp(float viewWidth, float viewHeight, float minPoints) {
    if (viewWidth <= 0 || viewHeight <= 0)
        return;
    const float minW = std::min(1.0f, minPoints / viewWidth);
    const float minH = std::min(1.0f, minPoints / viewHeight);
    for (TouchControl &control : controls) {
        control.width = std::clamp(control.width, minW, 1.0f);
        control.height = std::clamp(control.height, minH, 1.0f);
        control.x = std::clamp(control.x, 0.0f, 1.0f - control.width);
        control.y = std::clamp(control.y, 0.0f, 1.0f - control.height);
        control.opacity = std::clamp(control.opacity, 0.2f, 1.0f);
    }
}

bool TouchLayout::Save(const fs::path &path, std::string *error) const {
    std::error_code ec;
    fs::create_directories(path.parent_path(), ec);
    if (ec) {
        if (error) *error = "Could not create the layout directory: " + ec.message();
        return false;
    }
    const fs::path temporary = path.string() + ".tmp";
    std::ofstream out(temporary, std::ios::binary | std::ios::trunc);
    if (!out) {
        if (error) *error = "Could not write the layout file.";
        return false;
    }
    out << "NightPadTouchLayout " << version << '\n';
    out << "device " << TouchDeviceName(device) << '\n';
    for (const TouchControl &control : controls) {
        out << TouchControlName(control.id) << ' ' << control.x << ' ' << control.y << ' ' << control.width << ' '
            << control.height << ' ' << control.opacity << ' ' << (control.visible ? 1 : 0) << '\n';
    }
    out.close();
    if (!out) {
        if (error) *error = "Could not finish the layout file.";
        return false;
    }
    fs::rename(temporary, path, ec);
    if (ec) {
        fs::remove(temporary, ec);
        if (error) *error = "Could not activate the layout file.";
        return false;
    }
    return true;
}

bool TouchLayout::Load(const fs::path &path, std::string *error) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        if (error) *error = "The layout file is missing.";
        return false;
    }
    std::string header;
    int fileVersion = 0;
    std::string magic;
    std::getline(in, header);
    std::istringstream headerLine(header);
    headerLine >> magic >> fileVersion;
    if (magic != "NightPadTouchLayout" || fileVersion != version) {
        if (error) *error = "Unsupported touch-layout version.";
        return false;
    }
    std::string deviceName, key;
    in >> key >> deviceName;
    if (key != "device" || (deviceName != "phone" && deviceName != "tablet")) {
        if (error) *error = "The touch-layout device class is invalid.";
        return false;
    }
    TouchLayout loaded = Defaults(deviceName == "tablet" ? TouchDeviceClass::Tablet : TouchDeviceClass::Phone);
    loaded.controls.clear();
    std::string name;
    while (in >> name) {
        if (!KnownId(name))
            continue;
        TouchControl control;
        control.id = ParseId(name);
        int visible = 1;
        if (!(in >> control.x >> control.y >> control.width >> control.height >> control.opacity >> visible)) {
            if (error) *error = "A touch-layout row is incomplete.";
            return false;
        }
        control.visible = visible != 0;
        loaded.controls.push_back(control);
    }
    if (loaded.controls.empty()) {
        if (error) *error = "The touch layout has no controls.";
        return false;
    }
    *this = std::move(loaded);
    return true;
}

}  // namespace nightpad
