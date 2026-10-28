# Known issues

Status: current for the private candidate. Each entry says what a player or
tester would see, what is blocked, and where the detail lives.

## Open

| Issue | Effect | Detail |
| --- | --- | --- |
| No signing identity or device on this machine | Nothing physical has been installed; touch feel, controller rumble, campaign progression, performance and the final freeze are unverified | `docs/DEVICE-HANDOFF.md`, `docs/TEST-MATRIX.md` |
| The supplied image has only the 30 fps movie bundle | One action recording stops early on a movie the image lacks; NightPad writes `Region=NTSC` | `docs/STATUS.md`, G02 blocker |
| All-weapons assist is not wired | The menu offers immortality and unlimited ammo only | `docs/CHEATS-RESEARCH.md`, R20 |
| Texture overrides are not implemented | A `textures` folder does nothing | `docs/DECISIONS/0013-texture-overrides.md`, R21 |
| Driving objectives are not attributed per mission | The strings are located but not mapped to Paris, Alpine and the rest; headless runs do not reach the trigger | `docs/CAMPAIGN-INVENTORY.md`, G07 |
| Secret Unlocks have no automated path here | Only a device run through the original front end can confirm persistence | `docs/SOURCES.md`, R19 |
| Interrupted engine writes are untested | A crash during a save write has no evidence either way | R11 notes |
| Simulator shader compilation has no wall-clock budget | A cold session compiles hundreds of pipelines; startup timing must be measured from host/process clocks, not the game's in-session timestamps | `docs/DECISIONS/0014-simulator-metal.md` |
| Stopping from a non-title front-end page can black the next session | Stopping while the codename page is showing reliably makes the next Start render only a black game surface before the title. Stopping from the title page is the stable path. Save-flow and menu-manager resets did not fix it | `docs/GOAL-JOURNAL.md`, G05 repeated-session row |
| Driving Stop can exceed 60 seconds in audio cleanup | Action-to-driving handoff and driving gameplay work, but Stop can block in `Bond_CleanUp` destroying a sound stream. The shell reports the delayed stop rather than misreporting success | `docs/GOAL-JOURNAL.md`, G05 driving-stop row |
| Tablet sheet editing is not scriptable in this harness | Saving from the iPad form sheet and drag editing stay manual | `docs/TEST-MATRIX.md` |

## Not issues

- The pitch-black preview behind the touch overlay in the simulator is the
  shell preview without an engine, not a render failure.
- The first cell of a nested three-dot submenu cannot be tapped through the
  simulator accessibility bridge; a direct tap opens it.
- `scripts/verify_patches.sh` prints one whitespace warning for patch 0006; the
  reproduced files still match.
- A re-import keeps the replaced tree only for that session: the next launch
  clears it, so "Remove Previous Game Data" is a same-session action.
- The standalone driving harness defaults to the EU launch page's PAL video
  mode and therefore misses `paris_intro.mad`; the app's handover page is
  NTSC. It only affects direct `-mission` test runs, not the product path.
