#include "../../apple/shared/NightPadGameDataImport.h"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <unistd.h>

namespace fs = std::filesystem;
using nightpad::DataState;
using nightpad::GameDataImporter;
using nightpad::Paths;

static int failures = 0;

static void Check(bool condition, const char *what) {
    if (!condition) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

static void WriteFile(const fs::path &path, const std::string &text) {
    fs::create_directories(path.parent_path());
    std::ofstream out(path, std::ios::binary | std::ios::trunc);
    out << text;
}

static fs::path Prepared(const fs::path &root, char hashDigit, const std::string &marker) {
    fs::create_directories(root / "eurocom");
    fs::create_directories(root / "driving");
    WriteFile(root / "default.xbe", "action " + marker);
    WriteFile(root / "Driving.xbe", "driving " + marker);
    WriteFile(root / "eurocom" / "filesys.d00", std::string(128, hashDigit));
    WriteFile(root / "driving" / "marker.txt", marker);
    std::string hash(64, hashDigit);
    WriteFile(root / "manifest.json", "{\n  \"source\": { \"sha256\": \"" + hash + "\" }\n}\n");
    return root;
}

int main() {
    const fs::path home = fs::temp_directory_path() / ("nightpad-data-test-" + std::to_string(::getpid()));
    std::error_code ec;
    fs::remove_all(home, ec);
    const Paths paths = Paths::ForContainer(home);
    std::string error;
    Check(paths.CreateDirectories(&error), "container directories");
    Check(fs::is_directory(paths.gameData) && fs::is_directory(paths.saves) && fs::is_directory(paths.caches),
          "separate data classes");

    const fs::path sourceA = home / "incoming" / "A";
    Prepared(sourceA, 'a', "first");
    GameDataImporter first(paths);
    bool progressCalled = false;
    Check(first.Prepare(sourceA, [&](const char *, double fraction) {
              progressCalled = progressCalled || fraction >= 1.0;
          }, &error), "prepare valid data");
    Check(progressCalled, "progress reaches completion");
    Check(first.prepared(), "prepared state");
    Check(first.identity() == "data-" + std::string(20, 'a'), "identity from manifest");
    Check(fs::is_directory(first.stage()), "private staging exists");
    Check(!first.Activate(false, &error), "activation refused while running");
    Check(first.Activate(true, &error), "activation while stopped");
    std::string active;
    Check(first.CurrentState(&active, &error) == DataState::Ready, "ready after activation");
    Check(active == first.identity(), "active identity");
    Check(fs::is_regular_file(paths.GameDataFor(active) / "Driving.xbe"), "active tree present");

    WriteFile(paths.saves / "profile.sav", "durable-save");
    const fs::path sourceB = home / "incoming" / "B";
    Prepared(sourceB, 'b', "second");
    GameDataImporter second(paths);
    Check(second.Prepare(sourceB, nullptr, &error), "prepare replacement");
    Check(second.Activate(true, &error), "activate replacement");
    Check(second.previousDataRetained(), "previous data retained");
    Check(second.CurrentState(&active, &error) == DataState::Ready && active == second.identity(),
          "replacement active");
    Check(fs::is_regular_file(paths.GameDataFor(second.identity()) / "Driving.xbe"), "replacement tree present");
    Check(fs::is_regular_file(paths.saves / "profile.sav"), "saves unaffected by replacement");
    Check(fs::is_directory(second.previousPath()), "old identity retained off the active path");
    Check(second.DiscardStage(&error), "discard previous data stage");
    Check(!fs::exists(second.previousPath()), "previous data removed");

    const fs::path bad = home / "incoming" / "bad";
    fs::create_directories(bad / "eurocom");
    WriteFile(bad / "default.xbe", "x");
    GameDataImporter invalid(paths);
    Check(!invalid.Prepare(bad, nullptr, &error), "missing required file rejected");

    const fs::path linked = home / "incoming" / "linked";
    Prepared(linked, 'c', "linked");
    fs::create_symlink(linked / "default.xbe", linked / "alias.xbe", ec);
    GameDataImporter symlinked(paths);
    Check(!symlinked.Prepare(linked, nullptr, &error), "symlink rejected");

    const fs::path sourceC = home / "incoming" / "C";
    Prepared(sourceC, 'd', "cancelled");
    GameDataImporter cancelled(paths);
    cancelled.Cancel();
    Check(!cancelled.Prepare(sourceC, nullptr, &error), "cancelled import rejected");
    Check(cancelled.stage().empty(), "cancelled import leaves no stage");

    GameDataImporter cancelledAfter(paths);
    Check(cancelledAfter.Prepare(sourceC, nullptr, &error), "prepare for cancel cleanup");
    cancelledAfter.Cancel();
    Check(cancelledAfter.DiscardStage(&error), "cancel discards unactivated stage");
    Check(!fs::exists(cancelledAfter.stage()), "cancelled stage removed");

    WriteFile(paths.CurrentGameDataFile(), "{\"identity\":\"bad\"}\n");
    Check(second.CurrentState(&active, &error) == DataState::Ready, "stale pointer recovers by scanning GameData");
    const fs::path brokenHome = home / "broken";
    const Paths broken = Paths::ForContainer(brokenHome);
    Check(broken.CreateDirectories(&error), "broken container directories");
    WriteFile(broken.CurrentGameDataFile(), "{\"identity\":\"bad\"}\n");
    GameDataImporter brokenImporter(broken);
    Check(brokenImporter.CurrentState(&active, &error) == DataState::RecoverableError,
          "invalid pointer is recoverable error");

    fs::remove_all(home, ec);
    std::cout << (failures == 0 ? "data import: PASS" : "data import: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
