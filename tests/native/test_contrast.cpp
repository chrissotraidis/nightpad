#include "../../apple/shared/NightPadControlPalette.h"

#include <iostream>

using nightpad::ColourForControl;
using nightpad::ContrastWithWhite;
using nightpad::ControlColour;
using nightpad::RelativeLuminance;
using nightpad::TouchControlId;

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

int main() {
    Check(RelativeLuminance({0, 0, 0}) < 0.0001f, "black has no luminance");
    Check(ContrastWithWhite({0, 0, 0}) > 20.9f, "black on white is about 21:1");
    Check(ContrastWithWhite({1, 1, 1}) < 1.01f, "white on white is 1:1");

    for (int i = 0; i <= int(TouchControlId::Back); ++i) {
        const TouchControlId id = TouchControlId(i);
        const float contrast = ContrastWithWhite(ColourForControl(id));
        if (contrast < 4.5f) {
            std::cerr << "FAIL: " << nightpad::TouchControlName(id) << " contrast " << contrast << "\n";
            ++failures;
        }
    }

    std::cout << (failures == 0 ? "contrast: PASS" : "contrast: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
