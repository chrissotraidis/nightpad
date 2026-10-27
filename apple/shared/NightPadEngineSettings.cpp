#include "NightPadEngineSettings.h"

#include <sstream>

namespace nightpad {

std::string BuildEngineSettings(const std::string &discPath, const EngineDisplaySettings &display) {
    std::ostringstream out;
    out << "[Settings]\n";
    out << "DiscPath=" << discPath << "\n";
    out << "RenderWidth=" << display.renderWidth << "\n";
    out << "RenderHeight=" << display.renderHeight << "\n";
    out << "AntiAliasing=" << (display.antiAliasing ? 1 : 0) << "\n";
    out << "Widescreen=" << (display.widescreen ? "on" : "off") << "\n";
    out << "FOV=" << display.fov << "\n";
    out << "Region=NTSC\n";
    out << "FPS=60\n";
    return out.str();
}

}  // namespace nightpad
