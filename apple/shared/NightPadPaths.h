#ifndef NIGHTPAD_PATHS_H_
#define NIGHTPAD_PATHS_H_

#include <filesystem>
#include <string>

namespace nightpad {

// The app's data classes. Every path is explicit so tests can use a temporary
// container instead of a real home directory.
struct Paths {
    std::filesystem::path appSupport;   // Library/Application Support/NightPad
    std::filesystem::path gameData;     // appSupport/GameData/<identity>
    std::filesystem::path saves;        // appSupport/Saves
    std::filesystem::path launchState;  // appSupport/LaunchState
    std::filesystem::path caches;       // Library/Caches/NightPad
    std::filesystem::path diagnostics;  // Library/Logs/NightPad
    std::filesystem::path documents;    // the Files-visible Documents directory

    static Paths ForContainer(const std::filesystem::path &home);
    bool CreateDirectories(std::string *error) const;
    std::filesystem::path GameDataFor(const std::string &identity) const;
    std::filesystem::path CurrentGameDataFile() const;
};

}  // namespace nightpad

#endif  // NIGHTPAD_PATHS_H_
