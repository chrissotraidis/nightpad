# Decision 0023: native holds exclude elapsed gameplay time

Date: 2026-10-29

A fixed-build Uplink retest exposed a boundary missed by the earlier frame/audio
pause tests. The native menu holds the action thread, but multiplayer computes
elapsed time from `psiGetTimeIn100ths` on its next update. That clock continued
through the hold, so resuming consumed the paused interval and could immediately
end a match. Mission elapsed-play statistics use the same clock. Earlier native
frame and movie pause evidence remains valid on its measured scope; it does not
prove that the gameplay clock was held.

Patch 0037 records the action loop's observed pause interval and excludes it
from the original game's hundredths clock. Repeated pause requests do not move
the origin. Resume and Stop while paused balance it, and boot initialization
resets the clock state. A mutex protects queries made while the game thread is
held. The free-running host timestamp remains available for file/stream timeouts;
movie clocks keep their existing pause ownership. Replay time already stops with
its recorded frame counter and keeps the original arithmetic. No bridge exports,
profile format or input mapping changes.

The regression links the real engine, waits for its pause/audio boundary and
calls the production `MP_CheckForEndCondition` on an isolated unlimited-match
state while held. An 800 ms native hold increments multiplayer time by 810 ms
before the repair; afterward the gameplay clock and multiplayer elapsed time
stay unchanged while host time advances. Resume advances about 310 ms in a
300 ms interval, and Stop while paused followed by a second boot passes again.
The multiplayer globals are restored before the normal engine loop resumes.
`scripts/test_action_pause_clock.sh` is part of full engine verification.

Evidence: `build/tests/action-pause-clock-before.log` and
`build/tests/action-pause-clock/after.log`. Full engine verification, quick gates,
both iOS build lanes, 37-patch/83-file reconstruction, focused unchanged
CastleIndoors1 (635 frames) and unsigned package validation pass. The rebuilt
simulator Uplink match holds frame 15991 for at least 52 seconds; its countdown
resumes from 1:58 to 1:57. Six bots score objectives, human deaths/automatic
respawn and ammo pickup work, and original results/Replay return to a new match.
Clean Stop preserves all seven save files. Human frag/objective capture and full
multiplayer acceptance remain open. `evidence/action-pause-clock/result.json`
records the artifact and captures. Physical acceptance remains open. Navigation failures in the campaign do not establish a clock cause;
repeat affected gameplay after the repaired candidate is installed.
