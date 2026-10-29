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

// Independent landscape defaults, authored as centres and point sizes. The
// phone uses an Xbox diamond, aligned sticks and a compact D-pad above movement.
// Secondary buttons sit above the diamond; Start and Back share a system row.
constexpr DefaultControl Centred(TouchControlId id, float x, float y, float w, float h,
                                float referenceWidth, float referenceHeight) {
    return {id, (x - w * 0.5f) / referenceWidth, (y - h * 0.5f) / referenceHeight,
            w / referenceWidth, h / referenceHeight};
}
constexpr DefaultControl Phone(TouchControlId id, float x, float y, float w, float h) {
    return Centred(id, x, y, w, h, 800, 360);
}
constexpr DefaultControl Tablet(TouchControlId id, float x, float y, float w, float h) {
    return Centred(id, x, y, w, h, 1366, 960);
}
constexpr DefaultControl kPhone[] = {
    Phone(TouchControlId::LeftStick, 100, 260, 112, 112),
    Phone(TouchControlId::RightStick, 540, 260, 112, 112),
    Phone(TouchControlId::Dpad, 100, 156, 84, 84),
    Phone(TouchControlId::A, 714, 298, 48, 48),
    Phone(TouchControlId::B, 768, 244, 48, 48),
    Phone(TouchControlId::X, 660, 244, 48, 48),
    Phone(TouchControlId::Y, 714, 190, 48, 48),
    Phone(TouchControlId::LeftTrigger, 100, 80, 88, 48),
    Phone(TouchControlId::RightTrigger, 736, 80, 88, 48),
    Phone(TouchControlId::Start, 426, 334, 56, 44),
    Phone(TouchControlId::White, 682, 140, 44, 44),
    Phone(TouchControlId::Black, 742, 140, 44, 44),
    Phone(TouchControlId::Back, 360, 334, 56, 44),
};

// Tablet controls stay near the lower grip, with more spacing for the larger
// display. This is a separate composition rather than an enlarged phone row.
constexpr DefaultControl kTablet[] = {
    Tablet(TouchControlId::LeftStick, 100, 910, 160, 160),
    Tablet(TouchControlId::RightStick, 1000, 910, 144, 144),
    Tablet(TouchControlId::Dpad, 100, 600, 84, 84),
    Tablet(TouchControlId::A, 1220, 932, 56, 56),
    Tablet(TouchControlId::B, 1288, 886, 56, 56),
    Tablet(TouchControlId::X, 1152, 886, 56, 56),
    Tablet(TouchControlId::Y, 1220, 830, 56, 56),
    Tablet(TouchControlId::LeftTrigger, 100, 500, 104, 60),
    Tablet(TouchControlId::RightTrigger, 1220, 500, 104, 60),
    Tablet(TouchControlId::Start, 680, 910, 64, 44),
    Tablet(TouchControlId::White, 1170, 600, 52, 52),
    Tablet(TouchControlId::Black, 1270, 600, 52, 52),
    Tablet(TouchControlId::Back, 600, 910, 64, 44),
};

bool SquareControl(TouchControlId id) {
    return id == TouchControlId::LeftStick || id == TouchControlId::RightStick ||
        id == TouchControlId::Dpad || id == TouchControlId::A || id == TouchControlId::B ||
        id == TouchControlId::X || id == TouchControlId::Y ||
        id == TouchControlId::White || id == TouchControlId::Black;
}

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

TouchLayout TouchLayout::ForCanvas(float viewWidth, float viewHeight, float minPoints) const {
    TouchLayout result = *this;
    if (viewWidth <= 0 || viewHeight <= 0)
        return result;
    for (auto &control : result.controls) {
        const float cx = (control.x + control.width * 0.5f) * viewWidth;
        const float cy = (control.y + control.height * 0.5f) * viewHeight;
        float width = std::clamp(control.width * viewWidth, std::min(minPoints, viewWidth), viewWidth);
        float height = std::clamp(control.height * viewHeight, std::min(minPoints, viewHeight), viewHeight);
        if (SquareControl(control.id))
            width = height = std::min(width, height);
        control.width = width / viewWidth;
        control.height = height / viewHeight;
        control.x = std::clamp(cx - width * 0.5f, 0.0f, viewWidth - width) / viewWidth;
        control.y = std::clamp(cy - height * 0.5f, 0.0f, viewHeight - height) / viewHeight;
        control.opacity = std::clamp(control.opacity, 0.2f, 1.0f);
    }
    return result;
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
