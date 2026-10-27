#ifndef NIGHTPAD_GAME_DATA_IMPORT_H_
#define NIGHTPAD_GAME_DATA_IMPORT_H_

#include "NightPadPaths.h"

#include <atomic>
#include <functional>
#include <string>

namespace nightpad {

enum class DataState {
    Missing,
    Importing,
    Invalid,
    Ready,
    Launching,
    Running,
    RecoverableError,
};

using ImportProgress = std::function<void(const char *status, double fraction)>;

// Copies a prepared game-data tree into a private sibling stage, validates it,
// and only then swaps it into GameData/<identity>. Saves live outside this tree
// and are never touched. Prepare may run on a worker; Activate and Discard are
// main-thread operations for the shell and require the engine to be stopped.
class GameDataImporter {
public:
    explicit GameDataImporter(Paths paths);

    bool Prepare(const std::filesystem::path &preparedData, const ImportProgress &progress, std::string *error);
    void Cancel();
    bool Activate(bool runtimeStopped, std::string *error);
    bool DiscardStage(std::string *error);
    // Removes stage directories left behind by earlier runs. The active stage
    // and a retained previous tree are kept.
    bool CleanupAbandonedStages(std::string *error);
    // Removes identity trees other than the active one. Called once at launch,
    // when a retained previous tree is no longer reachable.
    bool RetainOnlyIdentity(const std::string &identity, std::string *error);

    bool prepared() const { return prepared_; }
    bool previousDataRetained() const { return previousDataRetained_; }
    const std::string &identity() const { return identity_; }
    const std::filesystem::path &stage() const { return stage_; }
    const std::filesystem::path &previousPath() const { return previousPath_; }

    // Reads LaunchState/current-game-data.json, falling back to a scan of
    // GameData/data-* when the pointer is missing.
    DataState CurrentState(std::string *identity, std::string *error) const;

private:
    Paths paths_;
    std::filesystem::path stage_;
    std::filesystem::path previousPath_;
    std::string identity_;
    std::atomic_bool cancelled_{false};
    bool prepared_ = false;
    bool previousDataRetained_ = false;
};

}  // namespace nightpad

#endif  // NIGHTPAD_GAME_DATA_IMPORT_H_
