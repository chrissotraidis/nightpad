#ifndef NIGHTPAD_BACKGROUND_POLICY_H_
#define NIGHTPAD_BACKGROUND_POLICY_H_

namespace nightpad {

// Pause when the app leaves the foreground only if it is actually playing and
// was not already held by native UI or by the player's own pause.
bool ShouldPauseForBackground(bool engineRunning, bool nativeUiPaused, bool alreadyPaused);

// Resume only the pause this policy created, and only if the engine is still
// running and still held.
bool ShouldResumeAfterBackground(bool backgroundPaused, bool engineRunning, bool enginePaused);

}  // namespace nightpad

#endif  // NIGHTPAD_BACKGROUND_POLICY_H_
