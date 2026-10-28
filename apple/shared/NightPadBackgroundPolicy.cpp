#include "NightPadBackgroundPolicy.h"

namespace nightpad {

bool ShouldHoldForNativeUI(const NativeUiPauseState &state) {
    return state.engineRunning && (state.menuVisible || state.surfaceVisible ||
                                   !state.applicationActive || state.alerts != 0);
}

bool ShouldPauseForBackground(bool engineRunning, bool nativeUiPaused, bool alreadyPaused) {
    return engineRunning && !nativeUiPaused && !alreadyPaused;
}

bool ShouldResumeAfterBackground(bool backgroundPaused, bool engineRunning, bool enginePaused) {
    return backgroundPaused && engineRunning && enginePaused;
}

}  // namespace nightpad
