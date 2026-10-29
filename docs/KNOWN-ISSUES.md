# Known issues

Status: current for the private candidate. Each entry says what a player or
tester would see, what is blocked, and where the detail lives.

## Open

| Issue | Effect | Detail |
| --- | --- | --- |
| Display acceptance is incomplete | Safe-area aspect fitting and driving widescreen flag encoding are fixed. Phone/tablet titles, driving HUD and the tablet widescreen scope have simulator evidence; action scope/FOV combinations, the remaining matrix and device performance remain unverified | `docs/DECISIONS/0017-display-fit-and-flow-timing.md`, R18 |
| Campaign completion/results save is not verified | Fresh codename, Paris and on-foot Exchange failure/replay work, but no mission/results save has been earned; failed attempts leave NPRUN byte-identical | `docs/TEST-MATRIX.md`, R09/R11 |
| SDL spatial audio lacks HRTF and I3DL2 reverb | The current backend mixes dry 3D voices with distance/pan. Hardware listening, route changes and full audio fidelity remain unverified | `src/action/sound/sdlAudioAction.cpp`, R10 |
| No signing identity or device on this machine | Nothing physical has been installed; touch feel, controller rumble, campaign progression, performance and the final freeze are unverified | `docs/DEVICE-HANDOFF.md`, `docs/TEST-MATRIX.md` |
| The supplied image has only the 30 fps movie bundle | One action recording stops early on a movie the image lacks; NightPad writes `Region=NTSC` | `docs/STATUS.md`, G02 blocker |
| All-weapons assist is not wired | The menu offers immortality and unlimited ammo only | `docs/CHEATS-RESEARCH.md`, R20 |
| Texture overrides are not implemented | A `textures` folder does nothing | `docs/DECISIONS/0013-texture-overrides.md`, R21 |
| Driving objectives are not attributed per mission | The strings are located but not mapped to Paris, Alpine and the rest; headless runs do not reach the trigger | `docs/CAMPAIGN-INVENTORY.md`, G07 |
| Secret Unlock physical coverage is incomplete | All five families, original simulator keyboard/save/relaunch and actual native menu/weapon effects pass; physical entry/persistence remain | `docs/TEST-MATRIX.md`, R19 |
| Physical save interruption and power-loss behavior remain unverified | Host fault tests and killed writers preserve complete profiles, with an atomic new save and previous-copy backup; signed-device acceptance remains | `docs/DECISIONS/0015-atomic-profile-saves.md`, R11 |
| Simulator shader compilation has no wall-clock budget | A cold session compiles hundreds of pipelines; startup timing must be measured from host/process clocks, not the game's in-session timestamps | `docs/DECISIONS/0014-simulator-metal.md` |
| The attract trailer is absent from the 30 fps bundle | For a boot that opens the attract page, `073a0048.xmv` cannot play, so that page is black until A skips it; the front end then loads normally | `docs/GOAL-JOURNAL.md`, G05 repeated-session row |
| Tablet sheet editing is not scriptable in this harness | Saving from the iPad form sheet and drag editing stay manual | `docs/TEST-MATRIX.md` |

## Not issues

- Native action holds now exclude elapsed gameplay time as well as frames/audio.
  Patch 0037 fixes the Uplink timer consuming the menu interval on resume; the
  actual PSI/MP-clock regression and simulator countdown hold pass. Decision
  0023 records the scope; physical acceptance remains open.

- Loaded profiles no longer override the native assists OFF choices. Patch 0036
  and decision 0022 have native production-CHET and simulator damage/death,
  Replay and explicit ON/OFF evidence. Both native choices are restored OFF;
  standalone/replay behavior remains original without app ownership.


- The sound-buffer overflow on later action boots has a source fix and native
  regression. Patch 0035 retires the previous 192 buffers before the next boot,
  retaining PCM ownership tracking and releasing old voices. Fifteen synthetic
  audio boots and fifteen real action lifecycle cycles pass; simulator/device
  audio acceptance remains. See decision 0021.

- A restart during an action movie now returns to the title. Patch 0034 resets
  the interrupted loader phase and per-boot launch-page cache; the real
  simulator Stop/Start and native boot regression pass. Decision 0020 records
  the cause and evidence. Campaign completion remains unverified.

- Driving Stop is fixed: the former 60-second hang was a 260-character host-path
  limit that kept the speech `.spe` big file from opening, leaving a sound
  stream waiting on a read that could not be issued. The path fix plus the
  stream-recovery and teardown guards make Stop return in 1.7-3.7 seconds on the
  simulator. See the 2026-10-28T05:00Z journal entry.

- A second Start in one app process no longer blacks the screen. The game-flow
  stack is a process static that ended the first session in `GAMEFLOW_GAME`, so
  the next boot skipped `GAMEFLOW_BOOT`; `GameFlow_ResetForBoot()` runs at each
  session start. Three consecutive Start/Stop cycles each reach the title, and
  the handoff to Paris still works. See the 2026-10-28T05:40Z journal entry.

- A mission followed by Stop and Start no longer crashes. The action engine's
  sound banks held sample memory in the session heap; the next session's
  `SFXReset` freed those pointers and faulted in `Mem_Free`. `SFXShutdown` now
  unloads the banks and stream at session cleanup while the heap is valid
  (patch 0025). A Paris mission, Stop and a fresh Start reach the title with no
  crash report.

- A repeated session no longer creates an SDL window without its Metal view.
  The GPU device retained per-window data after destruction; patch 0026 releases
  the window from the device first. The driving engine also clears its stale
  process-global device token, forcing a new device and swapchain. A complete
  action -> driving -> action -> driving route now renders the second Paris
  mission and reaches Mission Failed in the same process.

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
