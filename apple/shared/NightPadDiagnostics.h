#ifndef NIGHTPAD_DIAGNOSTICS_H_
#define NIGHTPAD_DIAGNOSTICS_H_

#include "NightPadPaths.h"

#include <cstdint>
#include <string>
#include <vector>

namespace nightpad {

struct DiagnosticContext {
    std::string appVersion;
    std::string buildConfiguration;   // diagnostic/debug or performance/release
    std::string generatedAt;
    std::string dataState;
    std::string dataIdentity;
    std::string engineState;
    std::string lastError;
    // Recent host-side events, oldest first. The report keeps the last twenty.
    std::vector<std::string> sessionEvents;
    std::string renderSize;
    std::string displayOptions;
    std::string assists;
    std::filesystem::path home;
    Paths paths;
    uint32_t threadCount = 0;
    uint64_t residentBytes = 0;
};

// Replaces the user's home and iOS container UUID, then removes common
// credential-looking values. The result is only a draft until the user shares it.
std::string RedactDiagnosticText(const std::string &text, const std::filesystem::path &home);

std::string BuildDiagnosticReport(const DiagnosticContext &context);

}  // namespace nightpad

#endif  // NIGHTPAD_DIAGNOSTICS_H_
