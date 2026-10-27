#include "NightPadPaths.h"

#include <system_error>

namespace nightpad {
namespace fs = std::filesystem;

Paths Paths::ForContainer(const fs::path &home) {
    Paths paths;
    paths.appSupport = home / "Library" / "Application Support" / "NightPad";
    paths.gameData = paths.appSupport / "GameData";
    paths.saves = paths.appSupport / "Saves";
    paths.launchState = paths.appSupport / "LaunchState";
    paths.caches = home / "Library" / "Caches" / "NightPad";
    paths.diagnostics = home / "Library" / "Logs" / "NightPad";
    paths.documents = home / "Documents";
    return paths;
}

bool Paths::CreateDirectories(std::string *error) const {
    std::error_code ec;
    for (const fs::path &path : { appSupport, gameData, saves, launchState, caches, diagnostics, documents }) {
        fs::create_directories(path, ec);
        if (ec) {
            if (error != nullptr)
                *error = "Could not create " + path.string() + ": " + ec.message();
            return false;
        }
    }
    return true;
}

fs::path Paths::GameDataFor(const std::string &identity) const {
    return gameData / identity;
}

fs::path Paths::CurrentGameDataFile() const {
    return launchState / "current-game-data.json";
}

}  // namespace nightpad
