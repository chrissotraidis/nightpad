#include "../../apple/shared/NightPadEngineSettings.h"
#include "action/engine/XboxSettings.h"

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unistd.h>

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

static int CheckEngineParser(bool widescreen) {
    char root[] = "/tmp/nightpad-engine-settings.XXXXXX";
    Check(mkdtemp(root) != nullptr, "isolated settings directory");
    if (failures != 0)
        return 1;
    Check(chdir(root) == 0, "enter settings directory");
    nightpad::EngineDisplaySettings display;
    display.widescreen = widescreen;
    display.fov = 70;
    {
        std::ofstream file("settings.ini");
        file << nightpad::BuildEngineSettings("/disc root/with space", display);
        Check(file.good(), "write app-generated settings");
    }
    // Call the real engine parser in a fresh process: its settings cache is
    // process-scoped. Checking only our own generated string missed on -> 0.
    Check(GetVideoMode() == (widescreen ? 1u : 0u), "engine sees the requested aspect mode");
    Check(XboxGetAVRegion() == 1, "engine selects NTSC media");
    Check(Settings_GetFPSOverride() == 60, "engine sees the frame cap");
    Check(Settings_GetFovDegrees() == 70.0f, "engine sees vertical FOV");
    Check(std::string(Settings_GetDiscPath()) == "/disc root/with space", "engine preserves the disc path");
    display.widescreen = !widescreen;
    display.fov = 80;
    {
        std::ofstream file("settings.ini");
        file << nightpad::BuildEngineSettings("/replacement disc", display);
        Check(file.good(), "write settings for the next session");
    }
    Settings_Reload();
    Check(GetVideoMode() == (widescreen ? 0u : 1u), "next session reloads the opposite aspect mode");
    Check(Settings_GetFovDegrees() == 80.0f, "next session reloads FOV");
    Check(std::string(Settings_GetDiscPath()) == "/replacement disc", "next session reloads the disc root");
    Check(chdir("/") == 0, "leave settings directory");
    std::filesystem::remove_all(root);
    std::cout << "engine settings parser (" << (widescreen ? "16:9" : "4:3") << "): "
              << (failures == 0 ? "PASS" : "FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}

int main(int argc, char **argv) {
    if (argc == 2)
        return CheckEngineParser(std::string(argv[1]) == "wide");
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
    Check(ValueOf(text, "Widescreen") == "1", "numeric widescreen flag written");
    Check(ValueOf(text, "FOV") == "70", "vertical FOV written");
    Check(ValueOf(text, "Region") == "NTSC" && ValueOf(text, "FPS") == "60", "runtime keys written");
    Check(text.rfind("[Settings]\n", 0) == 0, "section header first");

    display.antiAliasing = true;
    Check(ValueOf(nightpad::BuildEngineSettings("disc", display), "AntiAliasing") == "1", "FXAA default written");

    std::cout << (failures == 0 ? "engine settings: PASS" : "engine settings: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
