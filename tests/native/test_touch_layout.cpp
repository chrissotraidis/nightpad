#include "../../apple/shared/NightPadTouchLayout.h"

#include <filesystem>
#include <cmath>
#include <fstream>
#include <iostream>
#include <unistd.h>

namespace fs = std::filesystem;
using nightpad::TouchControlId;
using nightpad::TouchDeviceClass;
using nightpad::TouchLayout;

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

static bool Has(const TouchLayout &layout, TouchControlId id) {
    for (const auto &control : layout.controls)
        if (control.id == id)
            return true;
    return false;
}

int main() {
    const fs::path home = fs::temp_directory_path() / ("nightpad-layout-test-" + std::to_string(::getpid()));
    std::error_code ec;
    fs::remove_all(home, ec);
    fs::create_directories(home);

    TouchLayout phone = TouchLayout::Defaults(TouchDeviceClass::Phone);
    TouchLayout tablet = TouchLayout::Defaults(TouchDeviceClass::Tablet);
    Check(phone.controls.size() == 13 && tablet.controls.size() == 13, "all controls present");
    Check(std::string(TouchDeviceName(TouchDeviceClass::Phone)) == "phone" &&
              std::string(TouchDeviceName(TouchDeviceClass::Tablet)) == "tablet",
          "device names pick the layout file");
    Check(Has(phone, TouchControlId::Y) && Has(phone, TouchControlId::A) && Has(phone, TouchControlId::X) &&
              Has(phone, TouchControlId::B),
          "Xbox face controls");
    Check(phone.controls[1].width != tablet.controls[1].width, "phone/tablet defaults independent");

    // Defaults must stay usable, not just in bounds: at realistic landscape
    // sizes no visible control may cover another (the 44-point floor used to
    // push the face-button diamond into itself).
    struct LayoutCase {
        TouchLayout layout;
        float width;
        float height;
    };
    for (const LayoutCase &item : {
             LayoutCase{ phone, 844, 340 }, LayoutCase{ phone, 800, 320 },
             LayoutCase{ phone, 640, 320 },
             LayoutCase{ phone, 1024, 700 }, LayoutCase{ tablet, 1024, 700 },
             LayoutCase{ tablet, 1366, 1032 },
         }) {
        const std::pair<float, float> size{ item.width, item.height };
        const TouchLayout layout = item.layout.ForCanvas(size.first, size.second);
        for (size_t i = 0; i < layout.controls.size(); ++i) {
            const auto &control = layout.controls[i];
            Check(control.width * size.first >= 43.9f && control.height * size.second >= 43.9f,
                  "live targets retain the 44-point minimum");
            Check(control.x >= 0 && control.y >= 0 && control.x + control.width <= 1.0001f &&
                      control.y + control.height <= 1.0001f, "resolved controls remain inside canvas");
            if (control.id != TouchControlId::LeftTrigger && control.id != TouchControlId::RightTrigger &&
                control.id != TouchControlId::Start && control.id != TouchControlId::Back)
                Check(std::fabs(control.width * size.first - control.height * size.second) < 0.01f,
                      "drawn stick/face/D-pad rectangles are square in points");
            for (size_t j = i + 1; j < layout.controls.size(); ++j) {
                const auto &a = layout.controls[i];
                const auto &b = layout.controls[j];
                if (!a.visible || !b.visible)
                    continue;
                const bool apart = a.x + a.width <= b.x + 1e-4f || b.x + b.width <= a.x + 1e-4f ||
                                   a.y + a.height <= b.y + 1e-4f || b.y + b.height <= a.y + 1e-4f;
                const std::string message = std::string("visible controls overlap: ") +
                    nightpad::TouchControlName(a.id) + " / " +
                    nightpad::TouchControlName(b.id) + " at " +
                    std::to_string((int)size.first) + "x" +
                    std::to_string((int)size.second);
                Check(apart, message.c_str());
            }
        }
    }

    // Opening the editor or resolving a different screen must not rewrite a
    // saved layout. A compressed preview previously changed the saved minimum.
    const auto originalWidth = phone.controls[0].width;
    const auto originalY = phone.controls[0].y;
    (void)phone.ForCanvas(640, 320);
    (void)phone.ForCanvas(1024, 700);
    Check(phone.controls[0].width == originalWidth && phone.controls[0].y == originalY,
          "resolution leaves authored/saved geometry untouched");

    for (const auto &layout : {phone, tablet}) {
        auto centre = [&](TouchControlId id) {
            for (const auto &control : layout.controls)
                if (control.id == id)
                    return std::pair<float,float>{control.x + control.width * 0.5f,
                                                   control.y + control.height * 0.5f};
            return std::pair<float,float>{-1, -1};
        };
        const auto a = centre(TouchControlId::A), b = centre(TouchControlId::B);
        const auto x = centre(TouchControlId::X), y = centre(TouchControlId::Y);
        Check(std::fabs(a.first - y.first) < 0.001f && a.second > y.second &&
                  x.first < a.first && b.first > a.first && std::fabs(x.second - b.second) < 0.001f,
              "Xbox diamond has Y above A, X left and B right");
        Check(std::fabs(centre(TouchControlId::LeftStick).second -
                        centre(TouchControlId::RightStick).second) < 0.001f,
              "move and look sticks share the thumb row");
    }

    // 44-point minimum and safe-area clamp at an extreme landscape size.
    TouchLayout clamped = phone;
    clamped.controls[0].x = 2.0f;
    clamped.controls[0].y = -1.0f;
    clamped.controls[0].width = 0.001f;
    clamped.controls[0].height = 0.001f;
    clamped.controls[0].opacity = 0.0f;
    clamped.Clamp(640, 320, 44);
    const auto &stick = clamped.controls[0];
    Check(stick.width * 640 >= 43.9f && stick.height * 320 >= 43.9f, "44-point minimum");
    Check(stick.x >= 0 && stick.y >= 0 && stick.x + stick.width <= 1.0001f &&
              stick.y + stick.height <= 1.0001f,
          "safe-area clamp");
    Check(stick.opacity >= 0.2f, "opacity floor");

    // Round trip, reset and malformed/legacy handling.
    const fs::path path = home / "Controls" / "layout-phone.txt";
    std::string error;
    phone.controls[0].x = 0.11f;
    phone.controls[0].opacity = 0.55f;
    Check(phone.Save(path, &error), "save layout");
    TouchLayout loaded = TouchLayout::Defaults(TouchDeviceClass::Tablet);
    Check(loaded.Load(path, &error), "load layout");
    Check(loaded.device == TouchDeviceClass::Phone, "device restored");
    Check(loaded.controls[0].x == phone.controls[0].x && loaded.controls[0].opacity == phone.controls[0].opacity,
          "geometry restored");
    phone.controls[1].visible = false;
    Check(phone.Save(path, &error), "save hidden control");
    TouchLayout hidden = TouchLayout::Defaults(TouchDeviceClass::Phone);
    Check(hidden.Load(path, &error), "load hidden control");
    Check(!hidden.controls[1].visible && hidden.controls[0].visible, "visibility restored");
    loaded.Reset();
    Check(loaded.controls[0].x == TouchLayout::Defaults(TouchDeviceClass::Phone).controls[0].x, "reset to defaults");

    const fs::path bad = home / "bad.txt";
    std::ofstream(bad) << "NightPadTouchLayout 99\ndevice phone\n";
    TouchLayout invalid = TouchLayout::Defaults(TouchDeviceClass::Phone);
    Check(!invalid.Load(bad, &error), "unknown version rejected");
    const fs::path legacy = home / "legacy.txt";
    std::ofstream(legacy) << "NightPadTouchLayout 1\ndevice phone\n";
    Check(!invalid.Load(legacy, &error), "version-1 layout rejected");
    std::ofstream(path, std::ios::trunc)
        << "NightPadTouchLayout " << TouchLayout{}.version
        << "\ndevice phone\nunknown_control 0 0 0.1 0.1 0.7 1\n"
           "a 0.8 0.6 0.05 0.1 0.7 1\na 2 -1 0 0 2 1\n";
    Check(invalid.Load(path, &error), "loaded known rows");
    Check(invalid.controls.size() == 2, "unknown rows ignored");
    invalid.Clamp(640, 320);
    for (const auto &control : invalid.controls)
        Check(control.width > 0 && control.height > 0 && control.x + control.width <= 1.0001f,
              "loaded rows clamped");

    fs::remove_all(home, ec);
    std::cout << (failures == 0 ? "touch layout: PASS" : "touch layout: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
