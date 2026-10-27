#include "../../apple/shared/NightPadEngineSettings.h"

#include <iostream>
#include <sstream>
#include <string>

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

static std::string ValueOf(const std::string &text, const std::string &key) {
    std::istringstream in(text);
    std::string line;
    while (std::getline(in, line)) {
        if (line.rfind(key + "=", 0) == 0)
            return line.substr(key.size() + 1);
    }
    return {};
}

int main() {
    nightpad::EngineDisplaySettings display;
    display.renderWidth = 1280;
    display.renderHeight = 960;
    display.antiAliasing = false;
    display.widescreen = true;
    display.fov = 70;
    const std::string text = nightpad::BuildEngineSettings("/disc root/with space", display);
    Check(ValueOf(text, "DiscPath") == "/disc root/with space", "disc path preserved");
    Check(ValueOf(text, "RenderWidth") == "1280" && ValueOf(text, "RenderHeight") == "960", "render size written");
    Check(ValueOf(text, "AntiAliasing") == "0", "FXAA off written");
    Check(ValueOf(text, "Widescreen") == "on", "widescreen written");
    Check(ValueOf(text, "FOV") == "70", "vertical FOV written");
    Check(ValueOf(text, "Region") == "NTSC" && ValueOf(text, "FPS") == "60", "runtime keys written");
    Check(text.rfind("[Settings]\n", 0) == 0, "section header first");

    display.antiAliasing = true;
    Check(ValueOf(nightpad::BuildEngineSettings("disc", display), "AntiAliasing") == "1", "FXAA default written");

    std::cout << (failures == 0 ? "engine settings: PASS" : "engine settings: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
