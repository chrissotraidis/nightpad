# Decision 0010: in-process engine handoff

Date: 2026-10-27

## Result

NightPad owns the XBE hand-off inside the app process. The launch callback
records the requested image, asks the requesting game thread to stop and
returns ownership to the shell. The shell joins that thread, closes its window
and starts the named engine, which boots from the page the game already wrote
to `psiLaunch.bin`. No child process is started and the app stays alive across
an action-to-driving or driving-to-action transition.

The two engines keep separate copies of the input, pause and lifecycle
statics, so the host routes poll, pause, input suspension, pad publication and
rumble to the engine that is actually running. A newly started engine begins
unpaused and unsuspended, and the input feeder republishes its pads on the next
tick.

Driving gained the parity the native shell needs: a nonblocking window poll, a
cooperative pause that holds the simulation and pauses/resumes sound, a frame
counter for tests, and its own host-pad and rumble bridge.

## Evidence

- `scripts/test_engine_handoff.sh` starts action, triggers the game's own
  psiLaunchDriving path, receives `d:\driving.xbe`, joins action, then starts
  driving in the same process. Driving reads the 3072-byte page, boots
  `paris_mis01`, runs, requests `D:\DEFAULT.XBE` when stopped and joins.
- `scripts/test_driving_pause.sh` proves frames stop while paused and advance
  again after resume; the run joins cleanly.
- `scripts/test_action_pause.sh` still passes (frames 0 to 2, held 3 to 3,
  resumed 33).
- Both shell lanes build and the device link exports the driving poll, pause,
  input-suspension, host-pad and rumble bridges.

## Limits

Physical-device execution of a transition is unverified. Stopping the engine
very early in driving boot (seconds after start, before the loop begins)
previously crashed the process during cleanup; the gate now stops after boot.
Quit-during-loading-screen needs its own stability fix and test.
