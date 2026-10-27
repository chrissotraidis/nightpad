#include "../../apple/shared/NightPadSaves.h"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <unistd.h>

namespace fs = std::filesystem;

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

int main() {
    const fs::path root = fs::temp_directory_path() / ("nightpad-saves-test-" + std::to_string(::getpid()));
    std::error_code ec;
    fs::remove_all(root, ec);
    fs::create_directories(root);
    const fs::path launch = root / "LaunchState";
    const fs::path saves = root / "Application Support" / "NightPad" / "Saves";
    std::string error;

    Check(nightpad::EnsureSavesLink(launch, saves, &error), "link created");
    Check(fs::is_symlink(launch / "saves"), "launch/saves is a symlink");
    Check(nightpad::EnsureSavesLink(launch, saves, &error), "repeat call is idempotent");

    std::ofstream(launch / "saves" / "codename.dat") << "progress";
    Check(fs::exists(saves / "codename.dat"), "writes through the link land in Saves");
    Check(fs::is_regular_file(saves / "codename.dat"), "save file is durable in the target");

    // A real saves folder must be reported, never replaced.
    const fs::path other = root / "Other";
    fs::create_directories(other / "saves");
    std::ofstream(other / "saves" / "old.dat") << "old";
    std::string blockedError;
    Check(!nightpad::EnsureSavesLink(other, saves, &blockedError), "existing real folder is refused");
    Check(fs::exists(other / "saves" / "old.dat"), "existing saves are preserved");

    // A link to a different target is refused until someone decides.
    const fs::path third = root / "Third";
    fs::create_directory(third);
    fs::create_directory_symlink(root / "Elsewhere", third / "saves");
    Check(!nightpad::EnsureSavesLink(third, saves, &error), "misdirected link is reported");

    fs::remove_all(root, ec);
    std::cout << (failures == 0 ? "saves link: PASS" : "saves link: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
