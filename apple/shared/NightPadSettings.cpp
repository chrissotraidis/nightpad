#include "NightPadSettings.h"

#include <fstream>
#include <sstream>
#include <system_error>
#include <cstdlib>

namespace nightpad {
namespace fs = std::filesystem;

namespace {

bool ParseBool(const std::string &value, bool *out) {
    if (value == "1" || value == "true" || value == "on") {
        *out = true;
        return true;
    }
    if (value == "0" || value == "false" || value == "off") {
        *out = false;
        return true;
    }
    return false;
}

}  // namespace

bool AppSettings::Load(const fs::path &path, std::string *error) {
    std::ifstream in(path);
    if (!in) {
        if (error) *error = "The settings file is missing.";
        return false;
    }
    AppSettings loaded;
    std::string line;
    bool sawVersion = false;
    while (std::getline(in, line)) {
        if (!line.empty() && line.back() == '\r')
            line.pop_back();
        if (line.empty() || line[0] == '#')
            continue;
        const std::size_t equals = line.find('=');
        if (equals == std::string::npos) {
            if (error) *error = "A settings row has no value.";
            return false;
        }
        const std::string key = line.substr(0, equals);
        const std::string value = line.substr(equals + 1);
        if (key == "version") {
            char *end = nullptr;
            const long parsed = std::strtol(value.c_str(), &end, 10);
            if (value.empty() || end == value.c_str() || *end != '\0' || parsed < 0 || parsed > 100000) {
                if (error) *error = "The settings version is invalid.";
                return false;
            }
            loaded.version = static_cast<int>(parsed);
            if (loaded.version != version) {
                if (error) *error = "Unsupported settings version.";
                return false;
            }
            sawVersion = true;
        } else if (key == "touch_always_visible") {
            if (!ParseBool(value, &loaded.touchControlsAlwaysVisible)) {
                if (error) *error = "A settings value is invalid.";
                return false;
            }
        } else if (key == "auto_hide_touch") {
            if (!ParseBool(value, &loaded.hideTouchControlsWithController)) {
                if (error) *error = "A settings value is invalid.";
                return false;
            }
        } else if (key == "rumble") {
            if (!ParseBool(value, &loaded.rumble)) {
                if (error) *error = "A settings value is invalid.";
                return false;
            }
        }
        // Unknown keys, including another app's preferences, are ignored.
    }
    if (!sawVersion) {
        if (error) *error = "The settings file has no version.";
        return false;
    }
    *this = loaded;
    return true;
}

bool AppSettings::Save(const fs::path &path, std::string *error) const {
    std::error_code ec;
    fs::create_directories(path.parent_path(), ec);
    if (ec) {
        if (error) *error = "Could not create the settings directory: " + ec.message();
        return false;
    }
    const fs::path temporary = path.string() + ".tmp";
    std::ofstream out(temporary, std::ios::trunc);
    if (!out) {
        if (error) *error = "Could not write the settings file.";
        return false;
    }
    out << "version=" << version << '\n';
    out << "touch_always_visible=" << (touchControlsAlwaysVisible ? 1 : 0) << '\n';
    out << "auto_hide_touch=" << (hideTouchControlsWithController ? 1 : 0) << '\n';
    out << "rumble=" << (rumble ? 1 : 0) << '\n';
    out.close();
    if (!out) {
        if (error) *error = "Could not finish the settings file.";
        return false;
    }
    fs::rename(temporary, path, ec);
    if (ec) {
        fs::remove(temporary, ec);
        if (error) *error = "Could not activate the settings file.";
        return false;
    }
    return true;
}

}  // namespace nightpad
