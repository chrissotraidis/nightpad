#include "NightPadSaves.h"

#include <system_error>

namespace nightpad {
namespace fs = std::filesystem;

bool EnsureSavesLink(const fs::path &launchState, const fs::path &saves, std::string *error) {
    std::error_code ec;
    fs::create_directories(saves, ec);
    if (ec) {
        if (error) *error = "Could not create the saves directory: " + ec.message();
        return false;
    }
    fs::create_directories(launchState, ec);
    if (ec) {
        if (error) *error = "Could not create the launch directory: " + ec.message();
        return false;
    }
    const fs::path link = launchState / "saves";
    const fs::file_status status = fs::symlink_status(link, ec);
    if (!ec && fs::is_symlink(status)) {
        const fs::path target = fs::read_symlink(link, ec);
        if (!ec && fs::equivalent(target, saves, ec) && !ec)
            return true;
        if (error) *error = "The launch saves link points somewhere else.";
        return false;
    }
    if (!ec && fs::exists(status)) {
        if (error) *error = "The launch directory already has a saves folder.";
        return false;
    }
    fs::create_directory_symlink(saves, link, ec);
    if (ec) {
        if (error) *error = "Could not link the saves folder: " + ec.message();
        return false;
    }
    return true;
}

}  // namespace nightpad
