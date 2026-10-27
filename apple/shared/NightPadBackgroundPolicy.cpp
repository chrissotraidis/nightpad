#include "NightPadBackgroundPolicy.h"

namespace nightpad {

bool ShouldPauseForBackground(bool engineRunning, bool nativeUiPaused, bool alreadyPaused) {
    return engineRunning && !nativeUiPaused && !alreadyPaused;
}

bool ShouldResumeAfterBackground(bool backgroundPaused, bool engineRunning, bool enginePaused) {
    return backgroundPaused && engineRunning && enginePaused;
}

}  // namespace nightpad
