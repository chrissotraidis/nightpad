#include <cerrno>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <filesystem>
#include <fstream>
#include <string>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

enum class Fault {
    None, ShortWrite, InterruptedWrite, NoSpace, ZeroWrite, Read, FileSync,
    DirectorySyncBefore, DirectorySyncAfter, Close, BackupRename, CommitRename,
    KillBeforeCommit, KillAfterCommit
};
static Fault fault;
static unsigned writes;
static unsigned directorySyncs;

static ssize_t SaveTestWrite(int fd, const void *data, size_t size) {
    ++writes;
    if (fault == Fault::InterruptedWrite && writes == 1) {
        errno = EINTR;
        return -1;
    }
    if (fault == Fault::ZeroWrite)
        return 0;
    if (fault == Fault::NoSpace && writes > 1) {
        errno = ENOSPC;
        return -1;
    }
    if ((fault == Fault::ShortWrite || fault == Fault::NoSpace) && size > 1)
        size /= 2;
    return ::write(fd, data, size);
}

static ssize_t SaveTestRead(int fd, void *data, size_t size) {
    if (fault == Fault::Read) {
        errno = EIO;
        return -1;
    }
    return ::read(fd, data, size);
}

static int SaveTestSync(int fd) {
    struct stat info;
    if (::fstat(fd, &info) != 0)
        return -1;
    bool fail = fault == Fault::FileSync && S_ISREG(info.st_mode);
    if (S_ISDIR(info.st_mode)) {
        ++directorySyncs;
        fail = (fault == Fault::DirectorySyncBefore && directorySyncs == 1) ||
               (fault == Fault::DirectorySyncAfter && directorySyncs == 2);
    }
    if (fail) {
        errno = EIO;
        return -1;
    }
    return ::fsync(fd);
}

static int SaveTestClose(int fd) {
    struct stat info;
    bool fail = fault == Fault::Close && ::fstat(fd, &info) == 0 && S_ISREG(info.st_mode);
    int result = ::close(fd);
    if (fail) {
        errno = EIO;
        return -1;
    }
    return result;
}

static int SaveTestRename(const char *from, const char *to) {
    bool backup = std::string(to).ends_with(".bak");
    if ((fault == Fault::BackupRename && backup) || (fault == Fault::CommitRename && !backup)) {
        errno = EIO;
        return -1;
    }
    if (!backup && fault == Fault::KillBeforeCommit)
        ::kill(::getpid(), SIGKILL);
    int result = ::rename(from, to);
    if (!backup && result == 0 && fault == Fault::KillAfterCommit)
        ::kill(::getpid(), SIGKILL);
    return result;
}

// Faults affect the production writer's system calls in this translation unit.
// The application includes the same header with the ordinary POSIX calls.
#define write SaveTestWrite
#define read SaveTestRead
#define fsync SaveTestSync
#define close SaveTestClose
#define rename SaveTestRename
#include "action/engine/SaveFilePosix.h"
#undef write
#undef read
#undef fsync
#undef close
#undef rename

#include "action/engine/psiSave.h"

// Only the engine entry's directory creation needs a host service in this test.
int HostCreateDirectory(const char *path) {
    return ::mkdir(path, 0700) == 0;
}

static void Check(bool ok, const char *message) {
    if (!ok) {
        std::fprintf(stderr, "engine save: FAIL: %s (errno=%d)\n", message, errno);
        std::exit(1);
    }
}

static std::string Read(const std::filesystem::path &path) {
    std::ifstream input(path, std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(input), {});
}

static void Seed(const char *path, const std::string &data) {
    fault = Fault::None;
    Check(nightfire_save::WriteProfile(path, data.data(), data.size()), "seed profile");
    writes = directorySyncs = 0;
}

int main() {
    namespace fs = std::filesystem;
    char root[] = "/tmp/nightpad-engine-save.XXXXXX";
    Check(::mkdtemp(root) != nullptr, "isolated test directory");
    Check(::chdir(root) == 0, "enter test directory");
    fs::create_directory("saves");
    const std::string oldData = "PLRS" + std::string(162, 'a');
    const std::string newData = "PLRS" + std::string(162, 'b');
    const char *path = "saves/TEST.dat";
    Seed("saves/OTHER.dat", oldData);

    for (Fault current : {Fault::None, Fault::ShortWrite, Fault::InterruptedWrite, Fault::NoSpace,
                          Fault::ZeroWrite, Fault::Read, Fault::FileSync, Fault::DirectorySyncBefore,
                          Fault::DirectorySyncAfter, Fault::Close, Fault::BackupRename, Fault::CommitRename}) {
        Seed(path, oldData);
        fault = current;
        bool passed = nightfire_save::WriteProfile(path, newData.data(), newData.size());
        bool successExpected = current == Fault::None || current == Fault::ShortWrite ||
                               current == Fault::InterruptedWrite;
        Check(passed == successExpected, "write result reflects I/O failure");
        bool committed = successExpected || current == Fault::DirectorySyncAfter;
        Check(Read(path) == (committed ? newData : oldData), "complete old or new profile");
        if (committed)
            Check(Read("saves/TEST.dat.bak") == oldData, "recoverable previous profile");
        Check(Read("saves/OTHER.dat") == oldData, "unrelated profile untouched");
        for (const auto &entry : fs::directory_iterator("saves"))
            Check(entry.path().filename().string().find(".tmp.") == std::string::npos,
                  "failed operations clean their temporary files");
    }

    for (Fault current : {Fault::KillBeforeCommit, Fault::KillAfterCommit}) {
        Seed(path, oldData);
        pid_t child = ::fork();
        Check(child >= 0, "fork interrupted writer");
        if (child == 0) {
            fault = current;
            nightfire_save::WriteProfile(path, newData.data(), newData.size());
            _exit(2);
        }
        int status = 0;
        Check(::waitpid(child, &status, 0) == child && WIFSIGNALED(status) && WTERMSIG(status) == SIGKILL,
              "writer killed at commit boundary");
        Check(Read(path) == (current == Fault::KillBeforeCommit ? oldData : newData),
              "process interruption preserves a complete profile");
        Check(Read("saves/TEST.dat.bak") == oldData, "backup survives process interruption");
        unsigned profiles = 0;
        for (const auto &entry : fs::directory_iterator("saves")) {
            profiles += entry.path().extension() == ".dat";
            std::string name = entry.path().filename().string();
            if (name.find(".tmp.") != std::string::npos)
                Check(name.starts_with("."), "interrupted stages stay out of save exports");
        }
        Check(profiles == 2, "orphan stages and backups do not appear as codenames");
    }

    // Exercise the real psiSaveData/psiLoadData entry points and their UI result codes.
    fault = Fault::None;
    psiSaveData(const_cast<char *>(oldData.data()), oldData.size(), "ENGINE");
    Check(psiSavingData() == PSI_DONE, "engine save status");
    psiSaveData(const_cast<char *>(newData.data()), newData.size(), "ENGINE");
    Check(psiSavingData() == PSI_DONE, "engine replacement status");
    char loaded[166];
    uint32_t capacity = sizeof(loaded);
    psiLoadData(loaded, &capacity, "ENGINE");
    Check(psiLoadingData() == PSI_DONE && std::string(loaded, sizeof(loaded)) == newData,
          "engine reload preserves serialized bytes");
    Check(Read("saves/ENGINE.dat.bak") == oldData, "engine retains previous profile");
    fs::copy_file("saves/ENGINE.dat.bak", "saves/RECOVER.dat");
    psiLoadData(loaded, &capacity, "RECOVER");
    Check(psiLoadingData() == PSI_DONE && std::string(loaded, sizeof(loaded)) == oldData,
          "a restored previous copy reloads through the engine");
    psiSaveData(nullptr, 166, "ENGINE");
    Check(psiSavingData() == PSI_NOT_DONE && Read("saves/ENGINE.dat") == newData,
          "invalid save leaves existing profile intact");
    fs::create_directory("saves/BLOCKED.dat");
    psiSaveData(const_cast<char *>(newData.data()), newData.size(), "BLOCKED");
    Check(psiSavingData() == PSI_NOT_DONE, "engine reports a failed write");
    Check(SaveDrive_Delete("ENGINE") == PSISAVE_DELETED && !fs::exists("saves/ENGINE.dat") &&
          !fs::exists("saves/ENGINE.dat.bak"), "explicit codename deletion removes its backup");
    Check(::chdir("/") == 0, "leave test directory");
    fs::remove_all(root);
    std::puts("engine save: PASS (12 I/O cases, 2 killed writers, engine save/load/delete)");
}
