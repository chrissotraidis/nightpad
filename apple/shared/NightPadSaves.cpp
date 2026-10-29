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
        if (!ec) {
            std::error_code equivalentError;
            if (fs::equivalent(target, saves, equivalentError))
                return true;

            // App containers move on reinstall, update and simulator reset.
            // A link whose target no longer exists cannot hold saves, so it is
            // safe to repoint. A link to another live directory is not: that
            // may be a different profile, and replacing it could hide saves.
            std::error_code targetError;
            const bool targetExists = fs::exists(target, targetError);
            if (!targetError && !targetExists) {
                fs::remove(link, ec);
                if (ec) {
                    if (error) *error = "Could not remove the stale saves link: " + ec.message();
                    return false;
                }
                fs::create_directory_symlink(saves, link, ec);
                if (ec) {
                    if (error) *error = "Could not link the saves folder: " + ec.message();
                    return false;
                }
                return true;
            }
        }
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
