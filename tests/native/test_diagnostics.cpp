#include "../../apple/shared/NightPadDiagnostics.h"

#include <iostream>

using nightpad::BuildDiagnosticReport;
using nightpad::DiagnosticContext;
using nightpad::Paths;
using nightpad::RedactDiagnosticText;

static int failures = 0;

static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

int main() {
    const std::string home = "/Users/alice";
    const Paths paths = Paths::ForContainer(home);
    DiagnosticContext context;
    context.appVersion = "0.1.0";
    context.buildConfiguration = "diagnostic/debug";
    context.generatedAt = "2026-10-27T14:00:00Z";
    context.dataState = "Ready";
    context.dataIdentity = "data-8a0dc0e713f44e48b000";
    context.engineState = "paused";
    context.lastError = "token=supersecret password=hunter2";
    context.home = home;
    context.paths = paths;
    context.threadCount = 9;
    context.residentBytes = 123456789;

    const std::string report = BuildDiagnosticReport(context);
    Check(report.find("data_state=Ready") != std::string::npos, "data state");
    Check(report.find("engine_state=paused") != std::string::npos, "engine state");
    Check(report.find("thread_count=9") != std::string::npos, "thread count");
    Check(report.find("saves=~/Library/Application Support/NightPad/Saves") != std::string::npos,
          "home path redacted");
    Check(report.find("alice") == std::string::npos, "user name omitted");
    Check(report.find("supersecret") == std::string::npos && report.find("hunter2") == std::string::npos,
          "credential values redacted");
    Check(report.find("<redacted>") != std::string::npos, "redaction marker");
    Check(report.find("Nothing is uploaded") != std::string::npos, "review contract stated");

    const std::string container = RedactDiagnosticText(
        "/var/mobile/Containers/Data/Application/ABC-123/Documents/report.txt", home);
    Check(container.find("<app-container>/Documents/report.txt") != std::string::npos,
          "container UUID redacted");
    Check(container.find("ABC-123") == std::string::npos, "container id omitted");

    std::cout << (failures == 0 ? "diagnostics: PASS" : "diagnostics: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
