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
| The simulator has no SDL GPU | The shell UI runs there, but gameplay, audio and transitions need macOS engine gates or a device | `docs/STATUS.md` |
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
