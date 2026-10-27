# Goal journal

Append-only implementation decisions and evidence. Local private evidence paths
are ignored and may contain paths, hashes, captures or device identities.

## 2026-10-27T10:34:02Z — loop activated

- Goal: G00.
- Requirements: R02, R27.
- Hypothesis: the planning packet names complete public pins and the supplied
  reference image can be validated without changing it.
- Commands: source pin checks, toolchain inventory, ISO metadata and listing,
  guarded extractor build.
- Observed: all four public repositories checked out at their exact pins;
  FFmpeg matched its gitlink; Xcode and both SDKs are present; no signing
  identity or physical device is connected; the ISO listing has the required
  top-level content and no unsafe paths.
- Verdict: in progress.
- Next step: stage the image through the guarded script and read the XBE
  certificate; concurrently finish the native Mac build.

## 2026-10-27T11:05:00Z — baseline and platform boundary

- Goal: G02/G03.
- Requirements: R02, R03, R27; preliminary R06 evidence only.
- Hypothesis: the pinned graph can reproduce both native engines before iOS
  integration, and the 4 GB window survives the iOS linker/memory model.
- Source/build identity: Nightfire `8779cf79`, SDL `829a65d7`, SPIRV-Cross
  `f11ba9f0`, FFmpeg `8ae0b349`; Xcode 26.6, iPhoneOS/macOS 26.5.
- Commands: pinned native build, gamewindow probe, fused-op audit, replay
  corpus, driving lockstep run, iOS simulator and device builds, guarded VIV
  extraction.
- Observed: native targets and pointer probe pass. 11/12 recordings pass every
  frame; SpaceStationD lacks one movie. The iOS simulator pointer, Metal and XMV
  probes pass. The unsigned iPhoneOS arm64 app builds. No signing identity or
  physical device is available.
- Verdict: G02 partial pending second driving comparison; G03 simulator
  prerequisite passed and physical device blocked external.
- Next step: compare the repeated driving run; audit both engines' entry-point,
  global and cleanup ownership for G04.

## 2026-10-27T11:40:00Z — launch seam and static iOS dependencies

- Goal: G04.
- Requirements: R05, R07 in progress.
- Hypothesis: each engine can retain its globals in one isolated object, accept
  the original launch page in-process, and eliminate loose iOS dependencies.
- Observed: the 3,072-byte bridge test passes on a real pthread; both complete
  iPhoneOS engines build; static SDL and static FFmpeg link into the combined
  arm64 executable; only the four intended bridge symbols are exported.
- Verdict: component passed; lifecycle coordinator and transition runs remain.
- Next step: add start/stop ownership, join the game thread and quiesce audio,
  GPU and worker threads before starting the target engine.

## 2026-10-27T11:50:00Z — stop boundary exposes allocator and worker gaps

- Goal: G04.
- Observed: raw-link action start/stop reached Game_Main return and joined.
  Thread count rose 1 -> 6 and stayed at 7. Symbol-localized action crashed in
  ShaderMsl_Translate freeing a string; the raw-link build runs through the same
  startup and front end.
- Verdict: stop plumbing passes; lifecycle and isolation do not.
- Next experiment: one shared allocator/support runtime for both engines, SDL
  and SPIRV-Cross, then repeat start/stop/join with thread and heap checks.

## 2026-10-27T13:49:54Z — repeated launches and mixed transitions

- Goal: G04. Requirements: R05, R06, R07.
- Hypothesis: the second driving boot failed because the process-static heap and
  containers outlived their session; a narrow per-session reset plus in-window
  thread stacks should make repeated engine starts safe.
- Observed: the heap guard was re-arming only the first time, while
  `Bond_CleanUp` shut the allocator down. Re-arming the heap exposed stale file
  workers, file lists, EAGL pools, C++ locale facets, input lookups, Simulation
  maps, reference-counter trees, audio/voice/grid/targeting/AI/action-queue
  state, `PVehicle`'s name cache and the physics extension id. Each is now
  explicitly rebuilt after the new heap exists. Re-running the whole constructor
  table was rejected after it faulted in `AIVehicle::Construct` /
  `UMemory::FastAlloc`.
- Thread stacks were also exhausted in the general window by the third launch.
  They now come from the image's in-window arena, with a fallback to smaller
  reservations.
- Evidence: `scripts/test_driving_lifecycle.sh` passes three cycles; every join
  completes and the settled OS thread count is nine. `scripts/test_engine_transition.sh`
  passes three mixed cycles, six launch requests, both directions, every join,
  and a settled count of eight to nine. `scripts/test_action_lifecycle.sh`
  passes three cycles.
- Ten action-only cycles still fail after cycle six. Resident memory grows about
  105 MB per session, dominated by `IOAccelerator (graphics)` and owned graphics
  mappings. Destroying the device at the next start, before the window closes,
  reusing the device, waiting for GPU idle, and reusing the window were tried;
  none removed the growth. The persistent-window variant also leaked threads.
- Verdict: game-state/thread reset boundary passes; G04 remains in progress on
  the Metal/SDL session-resource leak and on physical-device evidence.
- Next experiment: profile the action engine's per-session GPU allocations
  (window claim, swapchain, textures, pipelines) and find the resource that the
  driver retains. Keep the ten-cycle soak as the gate.

## 2026-10-27T14:21:36Z — ten-cycle lifecycle gate

- Goal: G04. Requirements: R05, R06, R07.
- Hypothesis: the action failures were the two large per-session allocations
  (64 MB of GPU ring/upload buffers) and the action file system never closing
  its 64 operation slots; driving growth was a per-session texture/shader cache.
- Observed: the SDL GPU backend now keeps the device and its ring, transfer,
  back buffer, depth cache and black textures across sessions. The driving boot
  releases the previous game's textures, shaders, samplers and pipelines while
  preserving device-scoped resources. `FS_Init` closes the previous session's
  open handles and clears the async-stream table. The in-window reserve is 2 GB
  (1 GB heap arena plus 1 GB for repeated thread stacks), and stacks fall back
  through smaller reservations.
- Evidence: ten action cycles pass (224 MB to 248 MB resident, every join); ten
  driving cycles pass (warm to about 296 MB, tenth lower than ninth); ten mixed
  cycles pass, 20 launch requests in both directions, every join, settled 8-9 OS
  threads. Both complete iPhoneOS engines and the combined arm64 link rebuild.
- Verdict: the macOS G04 lifecycle/reset contract passes. Physical-device
  execution remains blocked external; G04 cannot close until that evidence
  exists.
- Next: start G05's native shell and data flow while device access remains
  unavailable, and keep all three ten-cycle scripts as regression gates.

## 2026-10-27T14:26:55Z — G05 path and import foundation

- Goal: G05. Requirements: R04 in progress.
- Hypothesis: the native shell needs one explicit path contract and one
  transactional import boundary before any menu or Files UI is built.
- Observed: `NightPadPaths` separates Application Support data, Saves, launch
  state, Caches, Logs and Documents. `GameDataImporter` copies a prepared tree
  into a private `GameData.import-*` stage, checks free space, validates the
  manifest identity and required game tree, rejects links and unsafe paths,
  reports progress, supports cancellation, and activates with Darwin's atomic
  `RENAME_SWAP`/`RENAME_EXCL`. Reimport updates the active pointer and retains
  the previous identity for explicit cleanup; saves are a separate tree and are
  never touched. A stale pointer recovers by scanning valid `GameData/data-*`
  directories.
- Evidence: `scripts/test_data_import.sh` passes invalid, symlink, cancellation,
  failed-activation, replacement, rollback and stale-pointer cases. The import
  core compiles into the iPhoneOS probe target.
- Verdict: R04's storage/transaction foundation is in place; the shell, import
  picker/progress UI, menu and pause wiring remain.
- Next: add the iOS shell target around the core and wire data status plus the
  persistent three-dot menu before integrating the engine session.

## 2026-10-27T14:32:45Z — native shell surface

- Goal: G05. Requirements: R04, R15 in progress.
- Hypothesis: a dedicated NightPad-shell target should expose the persistent
  menu and data controls without importing GalaxyPad's Nintendo-specific menu.
- Observed: added a landscape UIKit `NightPadShell` app with a persistent
  three-dot button, menu, game-data status/import panel, progress/cancel,
  previous-data cleanup, app-pause card, About card and diagnostics share entry.
  The import panel uses the tested `GameDataImporter`; the engine host is not yet
  attached, so Start Game is deliberately disabled and import activation uses
  the known-stopped state.
- Evidence: `scripts/build_ios_shell.sh simulator` and `device` both succeed.
  Simulator screenshots show home, open menu and data panel under
  `evidence/ios-shell/`; the simulator was shut down afterwards.
- Verdict: the shell surface and import UI foundation pass build/visual smoke;
  engine attachment, real pause/input gating and end-to-end picker import remain.
- Next: attach the combined engine host beneath the shell and connect menu/pause
  state to the coordinator, then run the Files import flow.

## 2026-10-27T14:37:38Z — engine archive linked into the shell

- Goal: G05. Requirements: R04, R15 in progress.
- Hypothesis: the shell target can carry both isolated engines as one archive
  without losing the symbol isolation proven by the standalone combined link.
- Observed: `build_combined_engine_link.sh` now emits
  `libnightpad-engines.a`; the iPhoneOS `NightPadShell` app links it with static
  SDL, FFmpeg and SPIRV-Cross. `NightPadEngineHost` prepares a private
  `settings.ini` from the active game-data path, sets the launch callback, and
  exposes action start/stop/join/close. The device app binary retains the action
  bridge and driving start; Start Game remains disabled until the SDL window and
  event loop are attached.
- Evidence: `scripts/build_ios_shell.sh device` passes; `nm` shows the engine
  bridge symbols in the signed-disabled app; the simulator shell still builds
  without the device-only archive.
- Verdict: link/staging boundary passes; live engine window and pause wiring are
  still incomplete.
- Next: create the SDL window under the shell overlay, run its event loop, and
  connect real stopped/pause/input state before enabling Start Game.

## 2026-10-27T14:43:28Z — host-owned live session loop

- Goal: G05. Requirements: R04, R15 in progress.
- Hypothesis: a nonblocking SDL poll loop can let the shell own its UIKit timer
  and overlay while the engine game thread renders independently.
- Observed: added `HostWindow_Poll`, exported as
  `NightPadActionEnginePollWindow`, and tracked it as
  `patches/0011-nonblocking-window-poll.patch`. The shell now prepares the
  active data path, starts the action engine, polls SDL at 60 Hz, raises a
  transparent pass-through shell window above the game, and requests
  stop/join/close from the menu. Import is blocked while the engine runs.
  Simulator shell UI still renders; simulator cannot run SDL GPU.
- Evidence: simulator/device shell builds succeed; `check_ios_shell_link.sh`
  confirms the poll bridge and no loose engine dylibs; the macOS ten-cycle
  transition gate still passes after the poll change.
- Verdict: build/event-loop boundary passes; live Start/Stop and input/pause
  behavior need a signed physical device run.
- Next: run the device shell, verify the SDL window/overlay composition, then
  add real engine pause and neutral-input/audio gating.

## 2026-10-27T14:52:35Z — native engine pause boundary

- Goal: G05. Requirements: R15 in progress.
- Hypothesis: a cooperative pause at the action loop boundary can freeze frame
  progress and suspend SFX/streams without destroying the session.
- Observed: `EngineLifecycle` now carries a pause flag separate from stop. The
  action loop pauses SFX and all streams, sleeps until resumed, unpauses on the
  way back, and exposes a frame counter and pause setter through the bridge. The
  shell App Pause uses the setter; Back to Game resumes.
- Evidence: `scripts/test_action_pause.sh` reports frames `0 -> 2`, paused
  `3 -> 3`, resumed `33`; the normal three-cycle action gate and the mixed
  transition gate still pass. Patch: `0012-native-engine-pause.patch`.
- Verdict: pause semantics and shell wiring pass on macOS; physical-device
  composition and neutral-input routing remain.
- Next: run the device shell through start/pause/resume/stop, then gate input
  and audio around native UI.

