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

// Landscape phone geometry: sticks in the lower corners, face cluster on the
// right, D-pad and triggers reachable by the left thumb, system buttons apart.
constexpr DefaultControl kPhone[] = {
    { TouchControlId::LeftStick, 0.035f, 0.54f, 0.17f, 0.34f },
    { TouchControlId::RightStick, 0.640f, 0.56f, 0.150f, 0.32f },
    { TouchControlId::Dpad, 0.235f, 0.58f, 0.14f, 0.28f },
    { TouchControlId::A, 0.930f, 0.66f, 0.055f, 0.124f },
    { TouchControlId::B, 0.864f, 0.72f, 0.055f, 0.124f },
    { TouchControlId::X, 0.864f, 0.58f, 0.055f, 0.124f },
    { TouchControlId::Y, 0.798f, 0.66f, 0.055f, 0.124f },
    { TouchControlId::LeftTrigger, 0.045f, 0.10f, 0.10f, 0.16f },
    { TouchControlId::RightTrigger, 0.855f, 0.10f, 0.10f, 0.16f },
    { TouchControlId::White, 0.075f, 0.30f, 0.075f, 0.14f },
    { TouchControlId::Black, 0.805f, 0.30f, 0.075f, 0.14f },
    { TouchControlId::Start, 0.545f, 0.06f, 0.055f, 0.11f },
    { TouchControlId::Back, 0.475f, 0.06f, 0.055f, 0.11f },
};

// Tablet geometry: more centre-to-edge space, still two hands.
constexpr DefaultControl kTablet[] = {
    { TouchControlId::LeftStick, 0.045f, 0.55f, 0.15f, 0.32f },
    { TouchControlId::RightStick, 0.700f, 0.56f, 0.120f, 0.30f },
    { TouchControlId::Dpad, 0.225f, 0.60f, 0.13f, 0.26f },
    { TouchControlId::A, 0.935f, 0.68f, 0.045f, 0.10f },
    { TouchControlId::B, 0.880f, 0.735f, 0.045f, 0.10f },
    { TouchControlId::X, 0.880f, 0.615f, 0.045f, 0.10f },
    { TouchControlId::Y, 0.825f, 0.68f, 0.045f, 0.10f },
    { TouchControlId::LeftTrigger, 0.055f, 0.10f, 0.085f, 0.14f },
    { TouchControlId::RightTrigger, 0.865f, 0.10f, 0.085f, 0.14f },
    { TouchControlId::White, 0.080f, 0.31f, 0.065f, 0.12f },
    { TouchControlId::Black, 0.825f, 0.31f, 0.065f, 0.12f },
    { TouchControlId::Start, 0.545f, 0.055f, 0.045f, 0.09f },
    { TouchControlId::Back, 0.485f, 0.055f, 0.045f, 0.09f },
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
