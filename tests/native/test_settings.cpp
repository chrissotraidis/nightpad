#include "../../apple/shared/NightPadSettings.h"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <unistd.h>

namespace fs = std::filesystem;
using nightpad::AppSettings;

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

int main() {
    const fs::path home = fs::temp_directory_path() / ("nightpad-settings-test-" + std::to_string(::getpid()));
    std::error_code ec;
    fs::remove_all(home, ec);
    fs::create_directories(home);
    const fs::path path = home / "settings.txt";
    std::string error;

    AppSettings settings;
    Check(settings.touchControlsAlwaysVisible == false && settings.hideTouchControlsWithController &&
              settings.rumble && settings.masterVolume == 100,
          "defaults");
    settings.touchControlsAlwaysVisible = true;
    settings.rumble = false;
    settings.masterVolume = 25;
    settings.renderScale = 3;
    settings.antiAliasing = false;
    settings.widescreen = true;
    settings.fov = 80;
    settings.assistImmortal = true;
    settings.assistUnlimitedAmmo = true;
    Check(settings.Save(path, &error), "save settings");

    AppSettings loaded;
    Check(loaded.Load(path, &error), "load settings");
    Check(loaded.touchControlsAlwaysVisible && !loaded.rumble && loaded.hideTouchControlsWithController,
          "round trip");
    Check(loaded.renderScale == 3 && !loaded.antiAliasing && loaded.widescreen, "display round trip");
    Check(loaded.fov == 80, "FOV round trip");
    Check(loaded.masterVolume == 25, "master volume round trip");
    Check(loaded.assistImmortal && loaded.assistUnlimitedAmmo, "assist round trip");

    // A donor's Nintendo preferences must not leak into NightPad.
    std::ofstream(path, std::ios::trunc) << "version=1\n"
                                           "controllerRumble=0\n"
                                           "modernCStick=1\n"
                                           "invertCStickVertical=1\n"
                                           "hideControls=1\n"
                                           "rumble=0\n";
    AppSettings fresh;
    Check(fresh.Load(path, &error), "unknown keys are tolerated");
    Check(!fresh.touchControlsAlwaysVisible && fresh.hideTouchControlsWithController && !fresh.rumble,
          "known keys applied and donor keys ignored");

    // Wrong version is refused without touching the current settings.
    std::ofstream(path, std::ios::trunc) << "version=9\nrumble=1\n";
    AppSettings kept;
    kept.rumble = false;
    Check(!kept.Load(path, &error), "unknown version rejected");
    Check(!kept.rumble, "rejected file leaves settings unchanged");

    // A missing version is not guessed.
    std::ofstream(path, std::ios::trunc) << "rumble=1\n";
    Check(!kept.Load(path, &error), "version is required");

    // A bad value is rejected.
    std::ofstream(path, std::ios::trunc) << "version=1\nrumble=maybe\n";
    Check(!kept.Load(path, &error), "invalid boolean rejected");

    std::ofstream(path, std::ios::trunc) << "version=1\nrender_scale=9\n";
    Check(!kept.Load(path, &error), "render scale out of range rejected");

    std::ofstream(path, std::ios::trunc) << "version=1\nfov=200\n";
    Check(!kept.Load(path, &error), "FOV out of range rejected");

    kept.masterVolume = 75;
    for (const char *invalid : {"-1", "101", "", "loud", "50x", "99999999999999999999999999"}) {
        std::ofstream(path, std::ios::trunc) << "version=1\nmaster_volume=" << invalid << '\n';
        Check(!kept.Load(path, &error), "invalid master volume rejected");
        Check(kept.masterVolume == 75, "invalid master volume keeps current settings");
    }
    for (int percent : {0, 100}) {
        settings.masterVolume = percent;
        Check(settings.Save(path, &error) && loaded.Load(path, &error) && loaded.masterVolume == percent,
              "master volume endpoints persist");
    }

    Check(!AppSettings{}.Load(home / "missing.txt", &error), "missing file reported");
    Check(error == "The settings file is missing.", "missing file has a readable reason");

    // A file written before the display and assist keys existed must keep its
    // known values and take defaults for the rest.
    std::ofstream(path, std::ios::trunc) << "version=1\nrumble=0\n";
    AppSettings older;
    Check(older.Load(path, &error), "older settings file loads");
    Check(!older.rumble && !older.touchControlsAlwaysVisible, "older known values kept");
    Check(older.renderScale == 1 && older.antiAliasing && !older.widescreen && older.fov == 60 &&
              !older.assistImmortal && !older.assistUnlimitedAmmo && older.masterVolume == 100,
          "newer keys default when absent");

    fs::remove_all(home, ec);
    std::cout << (failures == 0 ? "settings: PASS" : "settings: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
