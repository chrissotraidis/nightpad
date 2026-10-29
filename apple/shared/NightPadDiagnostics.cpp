#include "NightPadDiagnostics.h"

#include <algorithm>
#include <cctype>
#include <sstream>

namespace nightpad {
namespace fs = std::filesystem;

namespace {

std::string RedactLine(std::string line, const std::string &home) {
    if (!home.empty()) {
        // The home path can appear after a key or inside an event line, not
        // only at the start.
        for (size_t at = line.find(home); at != std::string::npos; at = line.find(home, at + 1))
            line.replace(at, home.size(), "~");
    }
    const std::string container = "/var/mobile/Containers/Data/Application/";
    const size_t containerAt = line.find(container);
    if (containerAt != std::string::npos) {
        const size_t begin = containerAt + container.size();
        size_t end = line.find('/', begin);
        if (end == std::string::npos)
            end = line.size();
        line.replace(begin, end - begin, "<app-container>");
    }
    static const char *const keys[] = { "token=", "password=", "secret=", "apikey=", "api_key=",
                                        "authorization=" };
    for (const char *key : keys) {
        const size_t at = line.find(key);
        if (at == std::string::npos)
            continue;
        size_t value = at + std::string(key).size();
        while (value < line.size() && line[value] == ' ')
            ++value;
        size_t end = value;
        while (end < line.size() && line[end] != ' ' && line[end] != ',' && line[end] != ';')
            ++end;
        if (end > value)
            line.replace(value, end - value, "<redacted>");
    }
    return line;
}

std::string SafePath(const fs::path &path, const fs::path &home) {
    const std::string text = path.string();
    const std::string homeText = home.string();
    if (text == homeText)
        return "~";
    if (!homeText.empty() && text.size() > homeText.size() && text.compare(0, homeText.size(), homeText) == 0 &&
        text[homeText.size()] == '/')
        return "~" + text.substr(homeText.size());
    return text;
}

}  // namespace

std::string RedactDiagnosticText(const std::string &input, const fs::path &home) {
    const std::string homeText = home.string();
    std::istringstream lines(input);
    std::ostringstream output;
    std::string line;
    while (std::getline(lines, line)) {
        output << RedactLine(line, homeText) << '\n';
    }
    return output.str();
}

std::string BuildDiagnosticReport(const DiagnosticContext &context) {
    std::ostringstream out;
    out << "NightPad local diagnostics\n";
    out << "generated_at=" << context.generatedAt << "\n";
    out << "app_version=" << context.appVersion << "\n";
    out << "build_configuration=" << context.buildConfiguration << "\n";
    out << "data_state=" << context.dataState << "\n";
    out << "data_identity=" << context.dataIdentity << "\n";
    out << "engine_state=" << context.engineState << "\n";
    if (!context.renderSize.empty())
        out << "render_size=" << context.renderSize << "\n";
    if (!context.displayOptions.empty())
        out << "display_options=" << context.displayOptions << "\n";
    if (!context.assists.empty())
        out << "assists=" << context.assists << "\n";
    out << "thread_count=" << context.threadCount << "\n";
    out << "resident_bytes=" << context.residentBytes << "\n";
    out << "application_support=" << SafePath(context.paths.appSupport, context.home) << "\n";
    out << "game_data_root=" << SafePath(context.paths.gameData, context.home) << "\n";
    out << "saves=" << SafePath(context.paths.saves, context.home) << "\n";
    out << "launch_state=" << SafePath(context.paths.launchState, context.home) << "\n";
    out << "caches=" << SafePath(context.paths.caches, context.home) << "\n";
    out << "diagnostics=" << SafePath(context.paths.diagnostics, context.home) << "\n";
    out << "documents=" << SafePath(context.paths.documents, context.home) << "\n";
    if (!context.lastError.empty())
        out << "last_error=" << context.lastError << "\n";
    const size_t firstEvent = context.sessionEvents.size() > 20 ? context.sessionEvents.size() - 20 : 0;
    for (size_t i = firstEvent; i < context.sessionEvents.size(); ++i)
        out << "session_event=" << context.sessionEvents[i] << "\n";
    out << "\nThis draft contains app paths and runtime state only. Saves, game data, screenshots, input captures and\n"
           "credentials are not included automatically. Review before sharing. Nothing is uploaded by NightPad.\n";
    return RedactDiagnosticText(out.str(), context.home);
}

}  // namespace nightpad
