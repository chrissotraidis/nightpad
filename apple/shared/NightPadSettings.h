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

    bool Load(const std::filesystem::path &path, std::string *error);
    bool Save(const std::filesystem::path &path, std::string *error) const;
};

}  // namespace nightpad

#endif  // NIGHTPAD_SETTINGS_H_
