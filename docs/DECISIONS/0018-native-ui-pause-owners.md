# Decision 0018: keep native UI pause owners independent

Date: 2026-10-28

Campaign testing exposed an unwired root menu. Modal panels called
`beginNativeUI`, but opening the primary-action UIButton menu did not. Earlier
host pause tests proved the engine boundary, not that this UIKit menu invoked
it. The prior claim that all shell menus already paused gameplay was too broad.

The menu button now uses UIControl's documented context-menu callbacks, as in
the pinned GalaxyPad donor's `apple/ios/GalaxyPadGameOverlay.mm` at
`4db10c4c11e35958aae8da23b4d80fe6e5fe88e3`. Dismissal reconciles at its start;
it does not depend on the iPad animator's optional completion. Menu rebuilding
is deferred while the menu is open.

Menu visibility, native surfaces/inline panels, outstanding alerts and app
activity independently own the host pause. Closing a menu cannot release an
open panel, and becoming inactive retains the hold until the app is active
again. This host pause does not change the original game's Start pause.
Starting or switching engines reapplies the gate and binds input even if UI
is still open. Alerts retain a hold while waiting for presentation.

On interruption, the input mixer clears pending edges and withholds each
source until its buttons, triggers and sticks are neutral. The existing
controller-join policy is preserved. Pure tests cover ownership transitions,
inactive dismissal, stacked alerts and independent release of input sources.
Physical controller ergonomics and interruptions remain unverified.

`--log-native-ui` enables private frame-count traces. In the iPhone simulator,
the action engine settles at frame 927, stays there through menu-to-layout
sheet transfer, then resumes after Cancel. Background/foreground with the
menu open retains a hold at frame 3685. The driving simulation settles at
1277 while its menu is open. The final build's App Pause and a nested menu
retain frame 1188 until Back to Game. Final quick gates and both iOS build
lanes pass. Evidence is in `evidence/native-ui-pause/` and
`build/tests/native-ui/`.

R15 still fails during blocking movie playback. `PlayMPC::Play` runs a movie
loop before the driving simulation counter starts, and does not poll
`EngineLifecycle_PauseRequested` or stop requests. The intro can finish while
the shell correctly reports a native hold and simulation frame zero. A fixed
simulation counter is therefore insufficient movie-pause evidence. The next
repair must pause the movie voice and clock, including silent/drained cases,
preserve time after resume, and observe stop while paused. Check both engines'
movie players and add a focused clock/movie regression before returning to
campaign acceptance. No campaign completion is credited here.
