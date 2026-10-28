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

// Landscape phone geometry inherited from GalaxyPad's overlay (its 800x380
// reference): the move stick lower-left with the D-pad above it, the camera
// stick lower-right, A large in the corner with B up-left of it, the light
// X/Y pair above, the right-rail key (GalaxyPad's Z) mapped to RT with the
// mirrored LT on the left, Start inward at the upper right, and White/Black/
// Back in GalaxyPad's auxiliary key row along the bottom.
constexpr DefaultControl kPhone[] = {
    { TouchControlId::LeftStick, 0.0448f, 0.6145f, 0.1575f, 0.3316f },
    { TouchControlId::RightStick, 0.8695f, 0.6997f, 0.1075f, 0.2263f },
    { TouchControlId::Dpad, 0.0000f, 0.2563f, 0.1650f, 0.3474f },
    { TouchControlId::A, 0.8800f, 0.4740f, 0.0975f, 0.2053f },
    { TouchControlId::B, 0.7938f, 0.6132f, 0.0725f, 0.1526f },
    { TouchControlId::X, 0.8746f, 0.3300f, 0.0575f, 0.1211f },
    { TouchControlId::Y, 0.8083f, 0.4663f, 0.0575f, 0.1211f },
    { TouchControlId::LeftTrigger, 0.0463f, 0.0595f, 0.0575f, 0.1211f },
    { TouchControlId::RightTrigger, 0.8963f, 0.0595f, 0.0575f, 0.1211f },
    { TouchControlId::Start, 0.6625f, 0.5595f, 0.1150f, 0.1211f },
    { TouchControlId::White, 0.3313f, 0.8195f, 0.0575f, 0.1211f },
    { TouchControlId::Black, 0.4038f, 0.8195f, 0.0575f, 0.1211f },
    { TouchControlId::Back, 0.5313f, 0.8195f, 0.0575f, 0.1211f },
};

// Tablet geometry: GalaxyPad's fixed iPad point sizes and reviewed centers on
// a 1366x1024 safe area. The controls stay the same physical size as the iPad
// grows instead of becoming tall, screen-relative pills.
constexpr DefaultControl kTablet[] = {
    { TouchControlId::LeftStick, 0.0681f, 0.7066f, 0.1259f, 0.1680f },
    { TouchControlId::RightStick, 0.8926f, 0.8290f, 0.0615f, 0.0820f },
    { TouchControlId::Dpad, 0.2204f, 0.7303f, 0.0966f, 0.1289f },
    { TouchControlId::A, 0.8536f, 0.6902f, 0.0761f, 0.1016f },
    { TouchControlId::B, 0.7962f, 0.7721f, 0.0556f, 0.0742f },
    { TouchControlId::X, 0.9367f, 0.6853f, 0.0454f, 0.0605f },
    { TouchControlId::Y, 0.9316f, 0.7567f, 0.0454f, 0.0605f },
    { TouchControlId::LeftTrigger, 0.0523f, 0.0997f, 0.0454f, 0.0605f },
    { TouchControlId::RightTrigger, 0.9023f, 0.0997f, 0.0454f, 0.0605f },
    { TouchControlId::Start, 0.8543f, 0.5478f, 0.0849f, 0.0605f },
    { TouchControlId::White, 0.3573f, 0.8195f, 0.0454f, 0.0605f },
    { TouchControlId::Black, 0.4273f, 0.8195f, 0.0454f, 0.0605f },
    { TouchControlId::Back, 0.5473f, 0.8195f, 0.0454f, 0.0605f },
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
