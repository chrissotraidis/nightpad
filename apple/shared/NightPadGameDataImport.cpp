#include "NightPadGameDataImport.h"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <fstream>
#include <random>
#include <system_error>
#include <vector>

#if defined(__APPLE__)
#include <sys/stdio.h>
#endif

namespace nightpad {
namespace fs = std::filesystem;

namespace {

constexpr uint64_t kImportHeadroom = 512ull << 20;
constexpr const char *kStagePrefix = "GameData.import-";

std::string RandomSuffix() {
    std::random_device device;
    static const char hex[] = "0123456789abcdef";
    std::string text;
    text.reserve(32);
    for (int i = 0; i < 32; ++i)
        text.push_back(hex[device() & 15]);
    return text;
}

bool ValidIdentity(const std::string &identity) {
    const std::string prefix = "data-";
    if (identity.size() != prefix.size() + 20 || identity.compare(0, prefix.size(), prefix) != 0)
        return false;
    for (size_t i = prefix.size(); i < identity.size(); ++i)
        if (!((identity[i] >= '0' && identity[i] <= '9') || (identity[i] >= 'a' && identity[i] <= 'f')))
            return false;
    return true;
}

bool ValidStageName(const std::string &name) {
    const std::string prefix = kStagePrefix;
    if (name.size() != prefix.size() + 32 || name.compare(0, prefix.size(), prefix) != 0)
        return false;
    for (size_t i = prefix.size(); i < name.size(); ++i)
        if (!((name[i] >= '0' && name[i] <= '9') || (name[i] >= 'a' && name[i] <= 'f')))
            return false;
    return true;
}

bool RequiredTree(const fs::path &root, std::string *error) {
    std::error_code ec;
    if (!fs::is_directory(fs::symlink_status(root, ec)) || ec) {
        if (error != nullptr) *error = "The prepared game-data folder is unavailable.";
        return false;
    }
    for (const char *file : { "default.xbe", "Driving.xbe" }) {
        if (!fs::is_regular_file(fs::symlink_status(root / file, ec)) || ec) {
            if (error != nullptr) *error = std::string("Required file is missing: ") + file;
            return false;
        }
    }
    for (const char *directory : { "eurocom", "driving" }) {
        if (!fs::is_directory(fs::symlink_status(root / directory, ec)) || ec) {
            if (error != nullptr) *error = std::string("Required folder is missing: ") + directory;
            return false;
        }
    }
    return true;
}

std::string ReadSmallFile(const fs::path &path) {
    std::ifstream input(path, std::ios::binary);
    if (!input)
        return {};
    std::string text;
    text.resize(1 << 20);
    input.read(&text[0], static_cast<std::streamsize>(text.size()));
    text.resize(static_cast<size_t>(input.gcount()));
    return text;
}

std::string ManifestIdentity(const fs::path &root, std::string *error) {
    const std::string manifest = ReadSmallFile(root / "manifest.json");
    const std::string key = "\"sha256\"";
    size_t at = manifest.find(key);
    if (at == std::string::npos) {
        if (error != nullptr) *error = "manifest.json has no source SHA-256.";
        return {};
    }
    at = manifest.find(':', at + key.size());
    at = manifest.find('"', at == std::string::npos ? at : at + 1);
    if (at == std::string::npos) {
        if (error != nullptr) *error = "manifest.json has a malformed source SHA-256.";
        return {};
    }
    ++at;
    std::string hash = manifest.substr(at, 64);
    if (hash.size() != 64 || hash.find_first_not_of("0123456789abcdef") != std::string::npos) {
        if (error != nullptr) *error = "manifest.json has an invalid source SHA-256.";
        return {};
    }
    return "data-" + hash.substr(0, 20);
}

bool CopyTree(const fs::path &source, const fs::path &destination, std::atomic_bool *cancelled,
              const ImportProgress &progress, uint64_t total, uint64_t *copied, std::string *error) {
    std::error_code ec;
    for (fs::recursive_directory_iterator it(source, fs::directory_options::none, ec), end; it != end;
         it.increment(ec)) {
        if (ec) {
            if (error != nullptr) *error = "Could not read the prepared data: " + ec.message();
            return false;
        }
        if (cancelled->load())
            return false;
        const fs::path relative = it->path().lexically_relative(source);
        bool unsafe = relative.empty();
        for (const fs::path &part : relative)
            unsafe = unsafe || part == ".." || part == ".";
        if (unsafe) {
            if (error != nullptr) *error = "The prepared data has an unsafe path.";
            return false;
        }
        const fs::file_status status = it->symlink_status(ec);
        if (ec) {
            if (error != nullptr) *error = "Could not inspect the prepared data: " + ec.message();
            return false;
        }
        if (fs::is_symlink(status) || (!fs::is_directory(status) && !fs::is_regular_file(status))) {
            if (error != nullptr) *error = "The prepared data contains a link or special file.";
            return false;
        }
        const fs::path target = destination / relative;
        if (fs::is_directory(status)) {
            fs::create_directories(target, ec);
        } else {
            fs::create_directories(target.parent_path(), ec);
            if (!ec)
                fs::copy_file(it->path(), target, fs::copy_options::overwrite_existing, ec);
            if (!ec) {
                *copied += fs::file_size(target, ec);
                if (progress != nullptr)
                    progress("Copying prepared game data", total == 0 ? 0.0 : double(*copied) / double(total));
            }
        }
        if (ec) {
            if (error != nullptr) *error = "Could not stage the prepared data: " + ec.message();
            return false;
        }
    }
    return !cancelled->load();
}

uint64_t TreeBytes(const fs::path &root) {
    std::error_code ec;
    uint64_t total = 0;
    for (fs::recursive_directory_iterator it(root, fs::directory_options::none, ec), end; it != end; it.increment(ec)) {
        if (ec)
            return 0;
        if (it->is_regular_file(ec) && !ec)
            total += it->file_size(ec);
    }
    return total;
}

void WriteCurrent(const Paths &paths, const std::string &identity) {
    std::error_code ec;
    fs::create_directories(paths.launchState, ec);
    const fs::path target = paths.CurrentGameDataFile();
    const fs::path temporary = target.string() + ".tmp";
    std::ofstream out(temporary, std::ios::binary | std::ios::trunc);
    if (out)
        out << "{\n  \"identity\": \"" << identity << "\"\n}\n";
    out.close();
    if (out)
        fs::rename(temporary, target, ec);
    if (ec)
        fs::remove(temporary, ec);
}

std::string PointerIdentity(const Paths &paths) {
    const std::string text = ReadSmallFile(paths.CurrentGameDataFile());
    const std::string key = "\"identity\"";
    size_t at = text.find(key);
    if (at == std::string::npos)
        return {};
    at = text.find(':', at + key.size());
    at = text.find('"', at == std::string::npos ? at : at + 1);
    if (at == std::string::npos)
        return {};
    ++at;
    const size_t end = text.find('"', at);
    return end == std::string::npos ? std::string{} : text.substr(at, end - at);
}

}  // namespace

GameDataImporter::GameDataImporter(Paths paths) : paths_(std::move(paths)) {}

void GameDataImporter::Cancel() {
    cancelled_.store(true);
    prepared_ = false;
}

bool GameDataImporter::Prepare(const fs::path &preparedData, const ImportProgress &progress, std::string *error) {
    if (prepared_ || !stage_.empty() || previousDataRetained_) {
        if (error != nullptr) *error = "A fresh import transaction is required.";
        return false;
    }
    // A cancel applies to the transaction that was running. A new Prepare is a
    // fresh transaction and must not inherit an earlier cancellation.
    cancelled_.store(false);
    previousDataRetained_ = false;
    previousPath_.clear();
    std::string detail;
    if (!RequiredTree(preparedData, &detail)) {
        if (error != nullptr) *error = detail;
        return false;
    }
    identity_ = ManifestIdentity(preparedData, &detail);
    if (!ValidIdentity(identity_)) {
        if (error != nullptr) *error = detail.empty() ? "The prepared data has no valid manifest identity." : detail;
        return false;
    }
    if (!paths_.CreateDirectories(&detail)) {
        if (error != nullptr) *error = detail;
        return false;
    }
    const uint64_t total = TreeBytes(preparedData);
    std::error_code ec;
    const fs::space_info space = fs::space(paths_.appSupport, ec);
    if (ec || space.available < total + kImportHeadroom) {
        if (error != nullptr) *error = "Not enough free storage for a private copy of the prepared data.";
        return false;
    }
    stage_ = paths_.appSupport / (std::string(kStagePrefix) + RandomSuffix());
    if (!fs::create_directory(stage_, ec) || ec) {
        stage_.clear();
        if (error != nullptr) *error = "Could not create import staging.";
        return false;
    }
    if (progress != nullptr)
        progress("Checking prepared game data", 0.0);
    uint64_t copied = 0;
    const bool copiedOk = CopyTree(preparedData, stage_, &cancelled_, progress, total, &copied, &detail);
    std::string check;
    const bool valid = copiedOk && !cancelled_.load() && RequiredTree(stage_, &check);
    if (!valid) {
        std::error_code ignored;
        fs::remove_all(stage_, ignored);
        stage_.clear();
        if (error != nullptr)
            *error = cancelled_.load() ? "Import cancelled." : (detail.empty() ? check : detail);
        return false;
    }
    prepared_ = true;
    if (progress != nullptr)
        progress("Prepared game data verified", 1.0);
    return true;
}

bool GameDataImporter::Activate(bool runtimeStopped, std::string *error) {
    if (!prepared_ || cancelled_.load() || !runtimeStopped || !ValidStageName(stage_.filename().string())) {
        if (error != nullptr) *error = "A verified import and a stopped game are required.";
        return false;
    }
    std::error_code ec;
    if (!fs::is_directory(fs::symlink_status(stage_, ec)) || ec) {
        if (error != nullptr) *error = "The verified import stage is unavailable.";
        return false;
    }
    const fs::path target = paths_.GameDataFor(identity_);
    const fs::file_status targetStatus = fs::symlink_status(target, ec);
    if (ec == std::errc::no_such_file_or_directory)
        ec.clear();
    if (ec) {
        if (error != nullptr) *error = "Could not inspect the active game data.";
        return false;
    }
    const bool replacing = fs::exists(targetStatus);
    if (replacing && (!fs::is_directory(targetStatus) || fs::is_symlink(targetStatus))) {
        if (error != nullptr) *error = "The active game-data path is not a directory.";
        return false;
    }
    const std::string oldIdentity = PointerIdentity(paths_);
    const bool hadOld = ValidIdentity(oldIdentity) && fs::is_directory(paths_.GameDataFor(oldIdentity), ec) && !ec;
#if defined(__APPLE__)
    if (renamex_np(stage_.c_str(), target.c_str(), replacing ? RENAME_SWAP : RENAME_EXCL) != 0) {
        if (error != nullptr) *error = "Could not activate the verified data; previous data is unchanged.";
        return false;
    }
#else
    if (replacing) {
        if (error != nullptr) *error = "Atomic replacement is unavailable on this host.";
        return false;
    }
    fs::rename(stage_, target, ec);
    if (ec) {
        if (error != nullptr) *error = "Could not activate the verified data; previous data is unchanged.";
        return false;
    }
#endif
    if (replacing) {
        previousPath_ = stage_;   // RENAME_SWAP leaves the old identity tree here
    } else if (hadOld && paths_.GameDataFor(oldIdentity) != target) {
        previousPath_ = paths_.GameDataFor(oldIdentity);
        stage_.clear();
    } else {
        stage_.clear();
    }
    previousDataRetained_ = !previousPath_.empty();
    prepared_ = false;
    WriteCurrent(paths_, identity_);
    return true;
}

bool GameDataImporter::DiscardStage(std::string *error) {
    fs::path victim = previousPath_;
    if (victim.empty() && ValidStageName(stage_.filename().string()))
        victim = stage_;
    if (victim.empty()) {
        if (error != nullptr) *error = "No import stage is available to discard.";
        return false;
    }
    std::error_code ec;
    fs::remove_all(victim, ec);
    if (ec) {
        if (error != nullptr) *error = "Previous data cleanup is still needed: " + ec.message();
        return false;
    }
    previousDataRetained_ = false;
    stage_.clear();
    previousPath_.clear();
    return true;
}

// A re-import leaves the replaced tree in its stage path. The shell can discard
// the newest one while it is still running, but anything left from an earlier
// launch is unreachable - and each tree is the size of the game data. Clear
// those, keeping the active stage and the retained previous tree.
bool GameDataImporter::CleanupAbandonedStages(std::string *error) {
    std::error_code ec;
    fs::directory_iterator entry(paths_.appSupport, ec);
    if (ec) {
        if (error != nullptr) *error = "Could not scan for abandoned imports: " + ec.message();
        return false;
    }
    const fs::directory_iterator end;
    while (entry != end) {
        const fs::path candidate = entry->path();
        entry.increment(ec);
        if (ec)
            break;
        if (!ValidStageName(candidate.filename().string()))
            continue;
        if ((!stage_.empty() && candidate == stage_) ||
            (!previousPath_.empty() && candidate == previousPath_))
            continue;
        fs::remove_all(candidate, ec);
        if (ec) {
            if (error != nullptr) *error = "An abandoned import could not be removed: " + ec.message();
            return false;
        }
    }
    return true;
}

DataState GameDataImporter::CurrentState(std::string *identity, std::string *error) const {
    std::error_code ec;
    std::string found = PointerIdentity(paths_);
    bool stalePointer = false;
    if (ValidIdentity(found) && RequiredTree(paths_.GameDataFor(found), nullptr)) {
        if (identity != nullptr) *identity = found;
        return DataState::Ready;
    }
    if (!found.empty() && fs::exists(paths_.CurrentGameDataFile(), ec))
        stalePointer = true;
    if (!fs::is_directory(paths_.gameData, ec)) {
        if (identity != nullptr) identity->clear();
        return DataState::Missing;
    }
    std::vector<std::string> candidates;
    for (fs::directory_iterator it(paths_.gameData, ec), end; it != end; it.increment(ec)) {
        if (ec)
            break;
        const std::string name = it->path().filename().string();
        if (ValidIdentity(name) && RequiredTree(it->path(), nullptr))
            candidates.push_back(name);
    }
    if (!candidates.empty()) {
        std::sort(candidates.begin(), candidates.end());
        if (identity != nullptr) *identity = candidates.back();
        return DataState::Ready;
    }
    if (stalePointer) {
        if (error != nullptr) *error = "The active game-data pointer is invalid.";
        return DataState::RecoverableError;
    }
    if (identity != nullptr) identity->clear();
    return DataState::Missing;
}

}  // namespace nightpad
