#ifndef NIGHTPAD_ENGINE_SETTINGS_H_
#define NIGHTPAD_ENGINE_SETTINGS_H_

#include <string>

namespace nightpad {

// The subset of the engine's settings.ini NightPad owns. RenderWidth and
// RenderHeight are the scene's internal size; AntiAliasing is 0 (off) or 1
// (FXAA); Widescreen enables the game's own wide-camera option.
struct EngineDisplaySettings {
    int renderWidth = 640;
    int renderHeight = 480;
    bool antiAliasing = true;
    bool widescreen = false;
};

std::string BuildEngineSettings(const std::string &discPath, const EngineDisplaySettings &display);

}  // namespace nightpad

#endif  // NIGHTPAD_ENGINE_SETTINGS_H_
