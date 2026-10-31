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

// The tablet default is the owner's own iPad Pro 12.9 arrangement: sticks in
// the lower thumb row with LT/RT just above them, the D-pad at the left edge,
// the face diamond in the right corner with White/Black above it, and Start/Back
// stacked at the right edge. Authored as normalized centres and sizes.
constexpr DefaultControl Norm(TouchControlId id, float cx, float cy, float w, float h) {
    return {id, cx - w * 0.5f, cy - h * 0.5f, w, h};
}
constexpr float kFaceW = 0.041f, kFaceH = 0.0583f;
constexpr float kFaceX = 0.918f, kFaceY = 0.826f, kFaceDx = 0.045f, kFaceDy = 0.054f;
constexpr DefaultControl kTablet[] = {
    Norm(TouchControlId::LeftStick, 0.1606f, 0.862f, 0.1171f, 0.1667f),
    Norm(TouchControlId::RightStick, 0.7632f, 0.862f, 0.1054f, 0.15f),
    Norm(TouchControlId::Dpad, 0.0551f, 0.7208f, 0.0615f, 0.0875f),
    Norm(TouchControlId::A, kFaceX, kFaceY + kFaceDy, kFaceW, kFaceH),
    Norm(TouchControlId::B, kFaceX + kFaceDx, kFaceY, kFaceW, kFaceH),
    Norm(TouchControlId::X, kFaceX - kFaceDx, kFaceY, kFaceW, kFaceH),
    Norm(TouchControlId::Y, kFaceX, kFaceY - kFaceDy, kFaceW, kFaceH),
    Norm(TouchControlId::LeftTrigger, 0.1632f, 0.7205f, 0.0761f, 0.0625f),
    Norm(TouchControlId::RightTrigger, 0.7657f, 0.7394f, 0.0761f, 0.0625f),
    Norm(TouchControlId::Start, 0.9592f, 0.565f, 0.0469f, 0.046f),
    Norm(TouchControlId::White, 0.913f, 0.660f, 0.0381f, 0.0542f),
    Norm(TouchControlId::Black, 0.9686f, 0.660f, 0.0381f, 0.0542f),
    Norm(TouchControlId::Back, 0.9592f, 0.495f, 0.0469f, 0.046f),
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

TouchGroup TouchGroupFor(TouchControlId id) {
    switch (id) {
        case TouchControlId::A:
        case TouchControlId::B:
        case TouchControlId::X:
        case TouchControlId::Y: return TouchGroup::Face;
        case TouchControlId::White:
        case TouchControlId::Black: return TouchGroup::Shoulders;
        case TouchControlId::Start:
        case TouchControlId::Back: return TouchGroup::System;
        default: return TouchGroup::None;
    }
}

bool SameTouchItem(TouchControlId a, TouchControlId b) {
    if (a == b)
        return true;
    const TouchGroup group = TouchGroupFor(a);
    return group != TouchGroup::None && group == TouchGroupFor(b);
}

namespace {

struct Box {
    float left = 1e9f, top = 1e9f, right = -1e9f, bottom = -1e9f;
};

Box ItemBox(const std::vector<TouchControl> &controls, TouchControlId id) {
    Box box;
    for (const auto &control : controls) {
        if (!SameTouchItem(id, control.id))
            continue;
        box.left = std::min(box.left, control.x);
        box.top = std::min(box.top, control.y);
        box.right = std::max(box.right, control.x + control.width);
        box.bottom = std::max(box.bottom, control.y + control.height);
    }
    return box;
}

void ShiftItem(std::vector<TouchControl> &controls, TouchControlId id, float dx, float dy) {
    for (auto &control : controls) {
        if (SameTouchItem(id, control.id)) {
            control.x += dx;
            control.y += dy;
        }
    }
}

// Moves the whole item back inside the canvas without changing its shape.
void KeepItemInside(std::vector<TouchControl> &controls, TouchControlId id) {
    const Box box = ItemBox(controls, id);
    float dx = 0, dy = 0;
    if (box.left < 0) dx = -box.left;
    else if (box.right > 1) dx = 1 - box.right;
    if (box.top < 0) dy = -box.top;
    else if (box.bottom > 1) dy = 1 - box.bottom;
    ShiftItem(controls, id, dx, dy);
}

}  // namespace

void TouchLayout::MoveItem(TouchControlId id, float dx, float dy) {
    ShiftItem(controls, id, dx, dy);
    KeepItemInside(controls, id);
}

void TouchLayout::ScaleItem(TouchControlId id, float factor, float viewWidth, float viewHeight, float minPoints) {
    if (!(factor > 0) || viewWidth <= 0 || viewHeight <= 0)
        return;
    const Box box = ItemBox(controls, id);
    if (box.right < box.left)
        return;
    const float cx = (box.left + box.right) * 0.5f, cy = (box.top + box.bottom) * 0.5f;
    // A group's members share one size: the average, so a stray enlarged button
    // is brought back in line the first time the group is resized.
    float sumW = 0, sumH = 0;
    int members = 0;
    for (const auto &control : controls) {
        if (SameTouchItem(id, control.id)) {
            sumW += control.width;
            sumH += control.height;
            ++members;
        }
    }
    const bool group = TouchGroupFor(id) != TouchGroup::None;
    // Never below the touch minimum, and never larger than the canvas.
    float smallest = 1e9f;
    for (const auto &control : controls) {
        if (!SameTouchItem(id, control.id))
            continue;
        const float w = group ? sumW / members : control.width;
        const float h = group ? sumH / members : control.height;
        smallest = std::min(smallest, std::min(w * viewWidth, h * viewHeight));
    }
    factor = std::max(factor, minPoints / std::max(smallest, 1.0f));
    const float span = std::max(box.right - box.left, box.bottom - box.top);
    if (span > 0)
        factor = std::min(factor, 1.0f / span);
    for (auto &control : controls) {
        if (!SameTouchItem(id, control.id))
            continue;
        const float w = group ? sumW / members : control.width;
        const float h = group ? sumH / members : control.height;
        const float mx = control.x + control.width * 0.5f, my = control.y + control.height * 0.5f;
        const float nx = cx + (mx - cx) * factor, ny = cy + (my - cy) * factor;
        control.width = w * factor;
        control.height = h * factor;
        control.x = nx - control.width * 0.5f;
        control.y = ny - control.height * 0.5f;
    }
    KeepItemInside(controls, id);
}

float TouchLayout::ItemScale(TouchControlId id) const {
    const TouchLayout defaults = Defaults(device);
    for (const auto &control : controls) {
        if (control.id != id)
            continue;
        for (const auto &original : defaults.controls)
            if (original.id == id && original.width > 0)
                return control.width / original.width;
    }
    return 1.0f;
}

void TouchLayout::SetItemVisible(TouchControlId id, bool visible) {
    for (auto &control : controls)
        if (SameTouchItem(id, control.id))
            control.visible = visible;
}

bool TouchLayout::ItemVisible(TouchControlId id) const {
    for (const auto &control : controls)
        if (control.id == id)
            return control.visible;
    return true;
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
    // Grouped buttons share one size (older editors resized them one by one).
    // Each keeps its centre, so the saved arrangement is otherwise unchanged.
    for (TouchGroup group : { TouchGroup::Face, TouchGroup::Shoulders, TouchGroup::System }) {
        float sumW = 0, sumH = 0;
        int members = 0;
        for (const auto &control : loaded.controls)
            if (TouchGroupFor(control.id) == group)
                sumW += control.width, sumH += control.height, ++members;
        if (members < 2)
            continue;
        for (auto &control : loaded.controls) {
            if (TouchGroupFor(control.id) != group)
                continue;
            const float cx = control.x + control.width * 0.5f, cy = control.y + control.height * 0.5f;
            control.width = sumW / members;
            control.height = sumH / members;
            control.x = cx - control.width * 0.5f;
            control.y = cy - control.height * 0.5f;
        }
    }
    *this = std::move(loaded);
    return true;
}

}  // namespace nightpad
