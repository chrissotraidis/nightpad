#ifndef NIGHTPAD_SETTINGS_H_
#define NIGHTPAD_SETTINGS_H_

#include <filesystem>
#include <string>

namespace nightpad {

// NightPad-owned preferences. The file is versioned and only names NightPad
// understands, so a donor's Nintendo-oriented preference file can never be
// adopted by accident.
struct AppSettings {
    int version = 1;
    bool touchControlsAlwaysVisible = false;
    bool hideTouchControlsWithController = true;
    bool rumble = true;
    // App output attenuation; 100 preserves the original game's mix.
    int masterVolume = 100;
    // 1 = original 640x480, 2..4 = that multiple for the scene's internal size.
    int renderScale = 1;
    bool antiAliasing = true;
    bool widescreen = false;
    // Vertical field of view in degrees; 60 is the game's own.
    int fov = 60;
    // Optional assists, off by default and never part of acceptance runs.
    bool assistImmortal = false;
    bool assistUnlimitedAmmo = false;
    // Every weapon and full ammo from the next mission start; all missions,
    // difficulties and multiplayer content in the original menus.
    bool assistAllWeapons = false;
    bool assistUnlockAll = false;
    // One opacity for the whole touch overlay, in percent (20-100).
    int touchOpacity = 70;

    bool Load(const std::filesystem::path &path, std::string *error);
    bool Save(const std::filesystem::path &path, std::string *error) const;
};

}  // namespace nightpad

#endif  // NIGHTPAD_SETTINGS_H_
