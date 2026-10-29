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

## 2026-10-27T14:56:00Z — native UI input suspension

- Goal: G05. Requirements: R15 in progress.
- Hypothesis: native surfaces must neutralize input before they cover the game,
  rather than relying on the paused sim loop to discard it later.
- Observed: `HostInput_SetSuspended` makes pad/keyboard reads neutral and drops
  pointer motion/wheel deltas. The bridge exports the switch; shell menu, data,
  About and pause surfaces suspend input and pause the engine while open, then
  release both when the native surface closes.
- Evidence: `patches/0013-native-input-suspension.patch`; simulator/device shell
  builds pass; device binary contains the input bridge; macOS pause and mixed
  transition gates still pass.
- Verdict: input/audio gating is wired at the native boundary; physical device
  behavior remains the gate.
- Next: run the device shell through menu-open/pause/resume and the Files import
  flow; inspect overlay/window composition on the phone and tablet.

## 2026-10-27T15:03:53Z — reviewable local diagnostics

- Goal: G05. Requirement: R25 in progress.
- Hypothesis: diagnostics should be a local draft the player can inspect before
  sharing, with no automatic upload or private container identifiers.
- Observed: added a portable report builder and UIKit review screen. The report
  records app/build identity, data and engine state, path classes, thread count
  and resident memory. Home paths and app-container UUIDs are redacted; common
  credential-looking values are removed. The shell writes the report atomically
  under Logs/NightPad and presents it with explicit Share and Done actions.
- Evidence: `scripts/test_diagnostics.sh` passes; simulator review screen
  renders (screenshot `evidence/ios-shell/diagnostics-preview.png`); simulator
  and device shell targets build; link check still passes.
- Verdict: review/export foundation passes; the actual share-sheet/save flow and
  device use remain unverified.
- Next: exercise Share/Save to Files, then continue G05 device composition and
  import flow once hardware access is available.

## 2026-10-27T15:05:57Z — diagnostics share/export smoke

- Goal: G05. Requirement: R25.
- Hypothesis: the reviewed report can be handed to the system share sheet
  without any automatic transmission or private container identifiers.
- Observed: the simulator share sheet exposes Save to Files and Copy for the
  report file. The file was found under the app's Logs/NightPad directory and
  read back; it contains app/data/engine state and path classes, with home paths
  and container ids removed. Evidence: `diagnostics-share.png` and
  `diagnostics-report.txt` under ignored `evidence/ios-shell/`.
- Verdict: the explicit export presentation passes; a deliberate Save to Files
  tap and device use remain unverified.
- Next: exercise the final save action and return to device shell composition /
  Files import when hardware access is available.

## 2026-10-27T15:08:56Z — About page and source notices

- Goal: G05. Requirements: branding/source disclosure under R25.
- Hypothesis: the About surface should identify NightPad and its donors without
  pretending to be affiliated with the game's rights holders.
- Observed: added a native About page with version, product description,
  Nightfire/GalaxyPad/SunPad links, non-affiliation and game-data notices, and
  accessibility identifiers. The old static About card was removed.
- Evidence: simulator screenshot `evidence/ios-shell/about.png`; simulator and
  device builds pass; link check unchanged.
- Verdict: surface and disclosure content pass; opening each external link and
  physical-device presentation remain unverified.
- Next: open-link smoke and the remaining device composition/import gates.

## 2026-10-27T15:11:50Z — shell import fixture

- Goal: G05. Requirement: R04.
- Hypothesis: the shell's picker handler and import transaction should work
  end-to-end without retail data when given a synthetic required tree.
- Observed: refactored the picker into one reusable import path and added a
  fixture launch hook. A synthetic prepared folder imported through validation,
  staging and activation; the active identity appeared after import and after
  relaunch; the existing save file remained byte-identical. The success alert and
  ready screen are captured under `evidence/ios-shell/`.
- Evidence: simulator import/ready screenshots; device shell builds; link check
  passes. The production Files picker still needs a prepared retail package.
- Verdict: shell import integration passes with synthetic data; retail-package
  picker flow and device run remain.
- Next: smoke the picker with a prepared retail folder on device, then finish
  the device composition gate.

## 2026-10-27T15:13:56Z — G06 four-port input mixer

- Goal: G06. Requirement: R14 in progress.
- Hypothesis: one Xbox-format mixer can own touch/controller merging, timing and
  port isolation before any layout or UIKit work.
- Observed: added `NightPadInput` with four ports, XInput-compatible button bits,
  neutral/dead-zone axes, trigger thresholds, rising-edge latching, per-source
  clear, controller-join release-before-reacquire and independent port state.
- Evidence: `scripts/test_input.sh` covers short taps across polls, dead zones,
  trigger thresholds, simultaneous sources, controller acquisition and port
  isolation. The core compiles into simulator/device shells.
- Verdict: input core passes; touch layout/editor, mapping UI, controller adapter
  wiring and physical runs remain.
- Next: build the Xbox touch layout and mapping adapter on this core.

## 2026-10-27T15:15:56Z — versioned touch-layout model

- Goal: G06. Requirement: R12 in progress.
- Hypothesis: normalized default geometry and a versioned atomic file can cover
  phone/tablet authoring and recovery without committing UIKit layout first.
- Observed: added independent landscape phone/tablet defaults for two sticks,
  D-pad, Xbox face buttons, LT/RT, White/Black and Start/Back; safe-area clamping,
  44-point minimum size and opacity bounds; atomic versioned persistence, reset,
  unknown-row tolerance and rejection of malformed/unknown versions.
- Evidence: `scripts/test_touch_layout.sh` passes; both shell targets build.
- Verdict: layout model/persistence passes; touch views, drag/resize editor,
  accessibility and physical ergonomics remain.
- Next: render the authored layout as UIKit controls and add the editor.

## 2026-10-27T15:25:00Z — touch-layout editor

- Goal: G06. Requirement: R12 in progress.
- Hypothesis: a UIKit canvas over the versioned layout can give the authored
  geometry a usable editor without new engine work.
- Observed: added `NightPadTouchLayoutViewController` with one view per control,
  Xbox colours/labels, drag and pinch gestures, 44-point clamping after every
  gesture, a Reset confirmation, explicit Cancel and Save, and a menu entry in
  the shell. The save path is `Controls/layout-<phone|tablet>.txt` under the app
  support directory.
- Observed: the first simulator render showed the face-button diamond collapsing
  into itself once the 44-point floor inflated heights on a short landscape
  canvas. The phone/tablet defaults were re-authored as a separated diamond and
  a new test asserts that no visible controls overlap at three landscape sizes.
- Evidence: both shell lanes build; `scripts/test_touch_layout.sh` passes. On the
  iPhone 17 simulator Save wrote the layout file, relaunching rendered a
  hand-edited `a 0.30 0.30` position, Reset restored the defaults and Save
  persisted them. The editor screenshot is under ignored
  `evidence/ios-shell/touch-layout-editor.png`.
- Verdict: editor and persistence pass on simulator; the in-game overlay,
  simultaneous gameplay touches, controller authority and physical runs remain.
- Next: feed the mixer into the engine and render the overlay during gameplay.

## 2026-10-27T16:05:00Z — overlay, controller authority and native menu

- Goal: G06. Requirements: R12, R14 in progress.
- Hypothesis: SunPad's structure — one pass-through overlay owning per-control
  views, one GameController authority, a native three-dot menu — transfers to
  Xbox semantics once the pad shape and mappings are NightPad's.
- Observed: added `NightPadTouchInput`, which turns live finger samples into an
  Xbox pad (stick vectors, eight-way D-pad, analog trigger depth, digital
  buttons, five simultaneous fingers). The shell now renders the authored
  layout over the game with press feedback, accessibility labels and
  auto-hide when a physical controller is present.
- Observed: added `NightPadControllerAuthority` over GameController with
  session-local player slots, LB/RB on White/Black, analog triggers, Start/Back
  and per-port Core Haptics rumble. The engine gained a host-pad override so SDL
  gamepads are bypassed while the app is the authority; rumble returns to the
  owning port.
- Observed: the shell's three-dot button is now a native UIMenu with Game,
  Controls, Game Data & Saves and Info submenus, following SunPad's menu shape
  instead of a custom card.
- Evidence: `scripts/test_touch_input.sh` and `scripts/test_controller_slots.sh`
  pass; both shell lanes build; the device link exports the host-pad and rumble
  bridge. Simulator evidence is under `evidence/ios-shell/touch-overlay.png` and
  `menu-controls.png`.
- Verdict: overlay, mapping, authority and menu pass their core and visual
  checks. Device connect/reconnect, rumble and multi-finger ergonomics remain
  unverified, and the game's own scheme/vehicle mappings are untouched.
- Next: verify the engine's pad consumption on device, then map Driving/POV
  definitions and the eight original schemes.

## 2026-10-27T16:35:00Z — contextual control help

- Goal: G06. Requirement: R13 in progress.
- Hypothesis: the game already consumes Xbox bits for every scheme, so the app
  owes players an accurate reference rather than a second mapping layer.
- Observed: added a native Controls page with on-foot, vehicle/turret and menu
  sections. Vehicle rows follow the supplied drivecfg.def and POV definitions
  (RT gas, LT brake, B handbrake, A secondary fire, X gadget, Y camera,
  White/Black and D-pad secondary selection).
- Evidence: the page renders on the iPhone 17 simulator from the Controls menu;
  screenshot at ignored `evidence/ios-shell/control-help.png`.
- Verdict: contextual help exists and matches the definitions; the eight
  schemes, inversion/aim preferences and vehicle behavior still need runtime
  verification with game data.
- Next: device pad verification, then a scheme/preference pass against the
  engine's own menus.

## 2026-10-27T16:55:00Z — versioned app settings

- Goal: G06. Requirement: R12 in progress.
- Hypothesis: a small NightPad-owned settings file can persist touch
  visibility, controller auto-hide and rumble without importing a donor's
  Nintendo keys.
- Observed: added `AppSettings` with an explicit version, atomic save, known-key
  parsing and unknown-key tolerance. The Controls menu now toggles auto-hide and
  rumble, and the touch-visibility choice persists.
- Evidence: `scripts/test_settings.sh` covers defaults, round trip, donor-key
  rejection, a wrong or missing version, invalid values and a missing file. In
  the simulator, turning rumble off wrote `settings.txt` with `rumble=0`; the
  relaunched menu showed Controller Rumble unselected.
- Verdict: settings persistence passes. Touch visibility still needs a gameplay
  run to exercise, and device behavior is unchanged.
- Next: confirm engine pad consumption on device; keep layout/settings gates in
  the regression set.

## 2026-10-27T17:10:00Z — controller auto-hide verified

- Goal: G06. Requirement: R12 in progress.
- Hypothesis: the persisted auto-hide choice drives the live overlay rather
  than only a stored flag.
- Observed: with the simulator's virtual gamepad connected, the overlay started
  hidden. Turning Auto-Hide off made the full overlay appear immediately, and
  `settings.txt` recorded `auto_hide_touch=0`.
- Verdict: visibility policy and persistence are wired together.
- Next: physical controller and touch sessions remain the external gate.

## 2026-10-27T17:20:00Z — controller lifecycle hooks

- Goal: G06. Requirement: R14 in progress.
- Hypothesis: re-enumerating GameController after foreground and neutralising
  ports on background removes stale slot and rumble state without device work.
- Observed: GameInput now reconciles on `UIApplicationDidBecomeActiveNotification`,
  releasing ports whose controller disappeared, and clears every port plus
  rumble when the app enters the background. Slot identity stays stable across
  a resume with the same enumeration.
- Evidence: both shell lanes build; slot reconciliation is covered by
  `scripts/test_controller_slots.sh`. Hardware sleep/wake remains unverified.
- Next: device session for connect/reconnect, held buttons and rumble.

## 2026-10-27T18:05:00Z — real game data through the shell import

- Goal: G05. Requirement: R04 in progress.
- Hypothesis: the shell's transaction path works on the real prepared tree, not
  only a synthetic fixture.
- Observed: copied the 1.9 GB, 56-file prepared tree into the app's
  Documents/ImportFixture and ran the shell import hook. Validation, staging and
  activation produced identity `data-a3c98ab965ac41e559ac`; relaunch reports
  "Game data ready". A second import left `Saves/slot1.sav` byte-identical
  (SHA-256 checked before and after).
- Observed: the Game Data menu's import action opens the system folder picker.
  Its remote view exposes no scriptable row actions to this harness, so choosing
  the folder remains a manual step.
- Evidence: ignored `evidence/ios-shell/data-ready-real.png`; container state
  under `Library/Application Support/NightPad`.
- Verdict: real-data import and save preservation pass; picker selection and
  device composition remain.
- Next: keep the device build ready for the handoff once a signing identity and
  hardware are available.

## 2026-10-27T19:25:00Z — in-process action-to-driving handoff

- Goal: G04. Requirements: R05, R07 in progress.
- Hypothesis: the engine's own psiLaunchDriving page can drive a real in-app
  transition if the shell joins the action thread and starts the named engine
  from `psiLaunch.bin`.
- Observed: a new macOS gate starts action, triggers the game's own driving
  request, joins action, then starts driving. Driving reads the 3072-byte page,
  boots `paris_mis01`, runs the intro and requests `D:\DEFAULT.XBE` when stopped
  before joining. Driving gained a nonblocking poll, cooperative pause with
  sound pause/resume, a frame counter and its own host-pad/rumble bridges.
- Observed: the shell host now records the requested image, stops the running
  engine on that thread, then joins, closes and starts the target; poll, pause,
  input suspension, pad publication and rumble are routed to the active engine.
- Evidence: `scripts/test_engine_handoff.sh` and `scripts/test_driving_pause.sh`
  pass; action pause still passes; both shell lanes build; the patch series
  applies to the pin. Decision recorded as 0010.
- Verdict: the campaign-direction transition works in-process on macOS. The
  iOS shell wiring compiles and links but cannot be exercised without hardware.
- Next: quit-during-loading stability, then device execution of the handoff.

## 2026-10-27T19:50:00Z — stop during boot is queued

- Goal: G04. Requirement: R05 in progress.
- Hypothesis: the observed crash came from running engine cleanup before the
  game loop had advanced; deferring the stop until the first frame avoids it
  from the app's side.
- Observed: a stop during boot previously crashed inside the driving engine's
  cleanup. The shell now keeps the stop request pending, shows
  "Stopping After Load…" and issues the stop once the active engine reports a
  frame (with a 180 s fallback).
- Evidence: both shell lanes build; the engine-level stop after frames is
  covered by the driving pause and lifecycle gates. The early-stop crash itself
  was reproduced only with the 8 s stopper and is not yet fixed in the engine.
- Verdict: the app-side crash path is guarded; the engine's partial-boot
  cleanup still needs a proper fix and a test.
- Next: reproduce the early-stop crash deterministically, then fix cleanup to
  tolerate a half-initialised engine.

## 2026-10-27T20:10:00Z — saves routed to the durable Saves directory

- Goal: G05. Requirement: R11 in progress.
- Hypothesis: the engine's relative `saves` folder can be a symlink into the
  app's Saves directory, so imports and launch-state rebuilds cannot strand a
  campaign.
- Observed: added `EnsureSavesLink` and call it when the engine host prepares
  a launch state. Writes through the link land in Saves; an existing real
  folder or a link to another target is reported instead of replaced.
- Evidence: `scripts/test_saves_link.sh` passes; both shell lanes build.
- Verdict: save redirection is wired and tested at the filesystem boundary; a
  real in-game save/relaunch is still required before R11 can pass.
- Next: run a real save and relaunch once device gameplay is available.

## 2026-10-27T20:35:00Z — one-command verification

- Goal: G00 (kept current). Requirement: R27.
- Hypothesis: the growing gate set needs two stable entry points so a
  regression cannot hide behind a forgotten script.
- Observed: added `scripts/verify_quick.sh` (host logic, shell builds, device
  link contract) and `scripts/verify_engine.sh` (lifecycle, pause, transition
  and handoff). Running the quick pass exposed a stale launch-bridge test that
  no longer linked `HostExitThread`; the test now links the POSIX host layer and
  passes.
- Evidence: quick verification passes end to end; the engine pass is the
  existing slow gates.
- Next: run both before each commit that touches engine or shell boundaries.

## 2026-10-27T21:10:00Z — campaign inventory from the front-end text

- Goal: G07. Requirement: R08 in progress.
- Hypothesis: the standalone action build stubs the documented `DumpFiles=on`
  option, so restoring it would expose the game's own data with real names.
- Observed: implemented the option in the standalone build (patch 0016). A
  front-end boot now writes eight named files under `dump/`, including
  `UKTxt.Dat`. Parsing that bank with the bundled tool yields the 18-entry
  campaign order (Training through Equinox) and nine multiplayer map names.
- Observed: the supplied driving data holds seven mission bundles
  (`mis01`, `mis3`, `mis4`, `mis11`, `mis13a/b/c`) whose engine names match the
  driving loop's intro/outro special cases.
- Evidence: `docs/CAMPAIGN-INVENTORY.md`; raw bank stays in ignored `build/`.
- Verdict: names, order and map list are inventoried. Mission scripts,
  transitions, movies per mission and the exact driving-bundle placement remain.
- Next: map each mission to its level script and driving bundle, then run the
  frozen first-play route.

## 2026-10-27T21:30:00Z — level table and recording coverage

- Goal: G07. Requirement: R08 in progress.
- Observed: the engine's hashcode table names 22 campaign levels
  (`0x07000005`..`0x0700001c`) and ten multiplayer levels, including the
  front-end's map names.
- Observed: the supplied recordings cover eight of those levels, and the
  CastleExterior recording itself crosses from `0x07000005` to `0x07000006`,
  so a transition is captured in existing evidence.
- Evidence: `docs/CAMPAIGN-INVENTORY.md`; demo log in ignored `build/`.
- Verdict: names, order, level ids and recording coverage are inventoried.
  Mission-to-level grouping still needs the front-end's mission table or a run
  per mission.

## 2026-10-27T21:45:00Z — mission wheel and level chains

- Goal: G07. Requirement: R08 in progress.
- Observed: the front-end mission wheel names twelve selectable missions and
  their start levels: five begin in driving levels (Paris, SnowMobile, Alps,
  Underwater, JungleA) and seven in action levels (CastleExterior, HendersonA,
  TowerA, PowerStationA1, Tower2A, EvilBase, SpaceStationD).
- Observed: `Mission.cpp` gives the level chains inside each mission (Castle 4,
  Henderson 4, Tower 3, PowerStation 2, Cut levels 2, Tower 2 four entries,
  Caves 1, EvilBase 3, SpaceStation 1). The driving bundles now match the five
  driving missions by name.
- Evidence: `docs/CAMPAIGN-INVENTORY.md`; source tables cited inline.
- Verdict: the mission-to-start-level and driving-bundle mapping is established
  from source. The six extra text headings, per-mission movies and objectives
  remain to be verified in a run.

## 2026-10-27T22:10:00Z — early engine stop is clean again

- Goal: G04. Requirement: R05 in progress.
- Hypothesis: the crash seen when stopping during driving boot was a stale
  build/timing artefact rather than a deterministic cleanup fault.
- Observed: a dedicated early-stop test requests a stop two seconds into
  driving boot (frames 0) and eight seconds in (frames 3577); both runs join and
  exit 0. The action engine stopped after one second also joins.
- Evidence: `scripts/test_driving_early_stop.sh`; added to the engine
  verification pass.
- Verdict: early stop is currently clean, but the earlier crash was not
  explained, so the shell keeps its stop-until-first-frame guard as defence.

## 2026-10-27T22:45:00Z — display options

- Goal: G09. Requirement: R18 in progress.
- Hypothesis: RenderWidth/RenderHeight already give the backend a larger
  internal target, so the app only needs to expose and persist the choices.
- Observed: added a Display menu with Original/2x/3x/4x resolution, AA off/FXAA
  and the game's 4:3/16:9 widescreen option, persisted in NightPad's settings
  and written to settings.ini at the next Start through a shared builder.
  Choosing 2x on the simulator persisted `render_scale=2`.
- Evidence: a macOS run with RenderWidth/Height 1280x960 logs
  `rendering the game's 640x480 at 1280x960`; `scripts/test_engine_settings.sh`
  checks the file content; screenshot under ignored `evidence/ios-shell/`.
- Verdict: the options are wired and the engine consumes them. Correct aspect,
  scope/HUD behaviour and sustained device performance at higher targets remain.

## 2026-10-27T23:20:00Z — media coverage and multiplayer inventory

- Goal: G07/G08. Requirements: R08 and R17 in progress.
- Observed: the supplied 30 fps bundle has sixteen XMV files whose names are the
  level hashcodes for exactly the seven action missions' intros and outros, plus
  two menu loops. Driving intros/outros live inside the mission VIVs, and the
  handoff gate has already played `paris_intro.mad`.
- Observed: source limits are four players plus six bots, ten maps, thirteen
  game modes, eleven weapon sets, three respawn modes and five Enviro-Mods
  options; Ravine disables bots, and arena/KOTH kills do not score.
- Evidence: `docs/CAMPAIGN-INVENTORY.md` (media section) and
  `docs/MULTIPLAYER-INVENTORY.md`.
- Verdict: inventory coverage is expanding without hardware. Mode/map support
  matrices, unlocks and every match behaviour remain to be exercised.

## 2026-10-27T23:40:00Z — cheat inventory

- Goal: G10. Requirement: R20 in progress.
- Observed: catalogued the original debug menu's checkboxes and the globals they
  drive. Immortal and all-weapons/unlimited-ammo are the two smallest useful
  assists; the rest are developer or performance switches.
- Observed: loading a codename resets the cheat state, so an assist must be
  applied after a level is live.
- Evidence: `docs/CHEATS-RESEARCH.md`; test-matrix entry.
- Verdict: research and a bounded plan are recorded. No assist is implemented,
  and none may enter core acceptance runs.

## 2026-10-28T00:10:00Z — immortality and unlimited-ammo assists

- Goal: G10. Requirement: R20 in progress.
- Hypothesis: applying the two flags from the action loop every frame keeps them
  alive across codename loads, so the app does not need per-level hooks.
- Observed: the loop now enforces the app's assist bits (patch 0017); the shell
  exposes an Assists submenu, persists both choices and re-applies them when
  action starts or returns from driving.
- Evidence: `scripts/test_assists.sh` boots action, sets both (engine reports
  3), clears them (engine reports 0) and joins. Immortality persisted as
  `assist_immortal=1` on the simulator; screenshot under ignored
  `evidence/ios-shell/`.
- Verdict: both flags work. The all-weapons equip is intentionally not wired,
  and none of this enters acceptance runs.

## 2026-10-28T00:45:00Z — campaign-shaped engine round trip

- Goal: G04. Requirement: R05/R07 in progress.
- Hypothesis: the app coordinator's whole loop can run in one process: action
  hands off to driving, driving hands back, and action boots from the second
  page.
- Observed: `scripts/test_engine_roundtrip.sh` starts action, lets the game's own
  psiLaunchDriving fire, joins it, starts driving (which reads the page and
  boots `paris_mis01`), stops it, then starts action again from the page
  driving wrote. All three phases advance frames and join; two launch requests
  are observed.
- Evidence: the gate; added to the engine verification pass.
- Verdict: the coordinator loop the campaign needs works in process on macOS.
  Device execution is still the gate.

## 2026-10-28T01:20:00Z — device handoff

- Goal: G03. Requirement: R27/handoff preparation.
- Observed: added `scripts/device_handoff.sh` and `docs/DEVICE-HANDOFF.md`. The
  script builds and links the device shell, reports the exact missing
  prerequisites (identity, trusted device, team), and signs, installs and
  launches with a console once they exist.
- Evidence: dry run builds the arm64 shell, passes the link check and reports
  zero identities and no devices, exiting 0. The install path is untested.
- Verdict: the smallest handoff is prepared. Nothing physical can be accepted
  until the machine has an identity and a trusted device.

## 2026-10-28T01:35:00Z — netplay deferred

- Goal: G11. Requirement: R22 decision complete; R23 not applicable.
- Observed: the reconstruction contains no `WSA*`, `XNet`, `XOnline`,
  `DirectPlay`, `sockaddr` or netplay code, and the front-end text has no
  system-link or online entries. The only multiplayer surface is local.
- Observed: two approaches were assessed — emulating Xbox System Link, or
  host-authoritative netplay — and both need architecture the project does not
  have; a prototype would still leave R23's two-device work open.
- Evidence: `docs/DECISIONS/0011-netplay-deferral.md`.
- Verdict: online play is deferred with a concrete reason; local multiplayer
  remains the supported scope.

## 2026-10-28T02:00:00Z — diagnostics carry session history

- Goal: G12. Requirement: R25 in progress.
- Observed: the report now lists render size, display options, assist state and
  the last twenty shell events: launch, import, engine start/stop, handoff,
  native pause/resume and errors. Event text goes through the same home-path
  and credential redaction, which was tightened to catch paths that do not
  start the line.
- Evidence: `scripts/test_diagnostics.sh` covers the new fields, the twenty
  event cap and redaction; a simulator report written from the app shows
  `render_size=1280x960`, display/assist state and a launch event.
- Verdict: device reports will be materially more useful. Diagnostic versus
  performance build separation and deliberate device collection remain.

## 2026-10-28T02:25:00Z — release lane and performance build identity

- Goal: G12. Requirement: R25 in progress.
- Observed: `build_ios_shell.sh` now takes `debug` or `release`; the Release
  simulator build reports `build_configuration=performance/release` when its
  diagnostics are opened, and the link check accepts a configuration.
- Evidence: `scripts/test_release_diagnostics.sh` builds Release, boots exactly
  one simulator, installs, opens diagnostics and asserts the report's build
  identity, then shuts the device down.
- Verdict: diagnostic and performance builds are distinguishable in the
  artifact itself. Deliberate device collection and performance measurement
  remain.

## 2026-10-28T02:40:00Z — difficulty and failure structure

- Goal: G07. Requirement: R08 in progress.
- Observed: three difficulties (Operative, Agent, 00 Agent) map to modifier
  values 1-3 and are applied in PlayerStats. Missions move through running,
  failed, died, timed out, waiting, won and countdown states; the timed-out
  state shows results after a win and the retry menu otherwise.
- Observed: the mission table gives per-level objective counts for every chain
  (Castle 1/1/2/2 through SpaceStationD 2).
- Evidence: `docs/CAMPAIGN-INVENTORY.md`; source tables cited inline.
- Verdict: the failure/restart and difficulty paths are mapped for testing.
  They still need to be exercised in a run.

## 2026-10-28T03:00:00Z — larger text in the touch overlay

- Goal: G06. Requirement: R29 in progress.
- Observed: overlay and editor labels now use `UIFontMetrics` for the headline
  style, capped at 20 and 22 points, and the shell status, editor hint and help
  text scale with content size. Controls keep their 44-point floor.
- Evidence: at the simulator's XXXL content size the overlay still fits every
  label; screenshot in ignored `evidence/ios-shell/`.
- Verdict: text sizing is exercised on the simulator. Contrast measurement,
  focus order and physical ergonomics remain.
- Follow-up: the editor hint wrapped to two lines at XXXL and squeezed the
  canvas enough for the face cluster to crowd. It is now a single short line
  capped at 17 pt, and the editor screenshot at XXXL shows the cluster separated
  again.

## 2026-10-28T03:30:00Z — save export

- Goal: G05. Requirement: R11 in progress.
- Hypothesis: the existing Saves directory can be exported with the system
  share sheet without inventing a new container format.
- Observed: Game Data > Share Saves collects the files in Saves and presents
  the system sheet; the simulator run shows two documents with Copy and Save to
  Files, and the sheet pauses the engine while open.
- Evidence: ignored `evidence/ios-shell/share-saves.png`.
- Verdict: backup/export has a real path now. Restoring a save, a real
  in-game save, and the app-update case remain.

## 2026-10-28T03:50:00Z — save restore

- Goal: G05. Requirement: R11 in progress.
- Observed: Import Saves opens the system document picker and copies the chosen
  files into the durable Saves directory. Same-name files trigger a
  confirmation before replacement, and cancelling the picker clears its state.
- Evidence: the picker presents on the simulator; screenshot under ignored
  `evidence/ios-shell/`. Selection is manual because the remote picker is not
  scriptable.
- Verdict: backup and restore now exist in the UI. A real in-game save,
  end-to-end restore and the app-update case remain.

## 2026-10-28T04:15:00Z — control contrast

- Goal: G06. Requirement: R29 in progress.
- Observed: the face colours lived twice (overlay and editor) and yellow/green
  fell below 4.5:1 against white labels. They now come from one shared palette
  with darker shades: green, red, blue, yellow and the neutrals all clear AA.
- Evidence: `scripts/test_contrast.sh` asserts 4.5:1 or better for every control
  and sanity-checks the luminance maths; the simulator overlay still reads as
  Xbox colours.
- Verdict: contrast is measured rather than eyeballed. Focus order and physical
  sessions remain.

## 2026-10-28T04:45:00Z — render cost on the host

- Goal: G09. Requirement: R18 in progress.
- Observed: Mission 1 played at 640x480, 1280x960 and 1920x1440 all reach the
  host's ~50 fps cap with 339-348 draws per frame. Working time ranged 11-20 ms
  with waiting compensating, so no resolution trend is visible.
- Evidence: `scripts/test_render_cost.sh`; raw logs under ignored `build/`.
- Verdict: higher targets run on the host, but the host is not GPU-bound. This
  says nothing about iPhone cost; device measurement decides the default.

## 2026-10-28T05:10:00Z — touch auto-hide follows the touch player

- Goal: G06. Requirement: R14 in progress.
- Observed: the overlay used to hide when *any* controller connected, so a
  player-two pad would hide player one's touch controls. The decision now uses
  only the controller assigned to port 0, expressed as a small shared policy.
- Evidence: `scripts/test_touch_policy.sh` covers the port-0 owner, a port-two
  controller, always-visible and auto-hide-off; the simulator's virtual pad on
  port 0 still hides the overlay when auto-hide is on.
- Verdict: the requirement's ownership rule holds in code and in the simulator.
  A real second controller is still needed to confirm slot assignment.

## 2026-10-28T05:35:00Z — overlay reading order

- Goal: G06. Requirement: R29 in progress.
- Observed: the accessibility tree used reverse subview order. The overlay now
  sets `accessibilityElements` explicitly: movement stick, D-pad, LT, White,
  Back, Start, Black, RT, look stick, then A, B, X, Y, with the menu last.
- Evidence: the simulator AX tree lists exactly that order.
- Verdict: reading order is deliberate. Physical VoiceOver use and the editor
  order still need a session.
- Follow-up: the same shared order now applies to the layout editor's canvas;
  its simulator AX tree lists L, D-PAD, LT, WHITE, BACK, START, BLACK, RT, R,
  A, B, X, Y, then Reset Layout.

## 2026-10-28T06:00:00Z — Secret Unlocks inventory

- Goal: G09. Requirement: R19 in progress.
- Observed: the codename menu's Secret Unlocks page holds 52 codes in five
  families: open all missions, toggle one mission, add a reward set, toggle one
  reward, or add weapon/gadget upgrades. Effects apply to the codename being
  edited and are saved with it; an unmatched code changes nothing.
- Observed: closing every mission leaves the first two open, and reward changes
  rebuild the player's upgrade set from the reward mask.
- Evidence: `docs/CAMPAIGN-INVENTORY.md` and the device handoff checklist. The
  codes themselves stay in source and ignored output.
- Verdict: the mechanism and a concrete device test plan are recorded. Physical
  entry and persistence remain.

## 2026-10-28T06:20:00Z — multiplayer map rules

- Goal: G08. Requirement: R17 in progress.
- Observed: Ravine disables AI bots in the setup wheel and empties the bot list;
  `Car_Create` refuses mini vehicles there; every map uses standard drone
  tuning. No source check ties a game mode to a map.
- Evidence: `docs/MULTIPLAYER-INVENTORY.md`, citing the setup wheel and object
  creation.
- Verdict: the map support matrix is source-complete except runtime
  confirmation that each mode family plays on at least two maps.

## 2026-10-28T06:40:00Z — patch provenance gate

- Goal: G13. Requirement: R26 in progress.
- Observed: the patch series was verified by hand after each engine change.
  `scripts/verify_patches.sh` now does it: a clean worktree at
  `8779cf79ff623b83b53b9acf9c0b0cd6639b75ab`, every patch applied in order, then
  a byte comparison with the vendor checkout. Linker map files are excluded
  because every build rewrites them.
- Evidence: 53 files reproduced; the gate is part of `verify_quick.sh`.
- Verdict: engine provenance is reproducible. A full clean-checkout build and
  package recipe remain.

## 2026-10-28T06:55:00Z — device package recipe

- Goal: G13. Requirement: R26 in progress.
- Observed: `scripts/package_device_app.sh` builds the Release app, packages
  `Payload/NightPadShell.app` into an unsigned IPA, checks the Info.plist and
  rejects loose dylibs.
- Evidence: a 3.6 MB IPA with SHA-256 `6f1f9667…44d3ec`; it is not installed
  because the machine cannot sign.
- Verdict: the package recipe reproduces. Signing/install and a clean-checkout
  build remain.

## 2026-10-28T07:10:00Z — multiplayer unlock matrix

- Goal: G08. Requirement: R17 in progress.
- Observed: the scenario wheel has 13 modes; seven are default and six
  (Uplink, Demolition, Protection, GoldenEye Strike, Assassination, Team KOTH)
  are reward-gated. Explosive Scenery is also gated. The character wheel has 29
  entries, 17 of them reward-locked (indices 12-28).
- Observed: mission medals and Secret Unlocks write the same reward mask, so
  both routes open the same content and the codename save persists it.
- Evidence: `docs/MULTIPLAYER-INVENTORY.md`, from the scenario and character
  tables plus the unlock code.
- Verdict: the unlock matrix is source-complete. Runtime checks remain with the
  rest of multiplayer.

## 2026-10-28T07:30:00Z — vertical field of view

- Goal: G09. Requirement: R18 in progress.
- Observed: the engine's FOV key is a vertical angle defaulting to 60, clamped
  to 30-120, with scopes unchanged. Display now offers 60 (original), 70 and 80,
  persists the choice and writes `FOV=` into settings.ini at the next Start.
- Evidence: the settings round-trip and engine-file tests pass; choosing 70 on
  the simulator wrote `fov=70`.
- Verdict: the option is wired. Aspect, HUD and scope behaviour at each value
  still need visual validation, which is device work.

## 2026-10-28T07:50:00Z — pause gates audio

- Goal: G05. Requirement: R15 in progress.
- Observed: the pause tests only proved frames stopped. Both engines now expose
  their audio pause state: action reports SFX and all streams paused then
  resumed, driving reports the sound manager paused then resumed.
- Evidence: `scripts/test_action_pause.sh` logs `audio 1/1`;
  `scripts/test_driving_pause.sh` logs `audio-paused=1 audio-resumed=1`.
- Verdict: native pause gates both gameplay and audio in the engine layer. The
  shell's menu/editor path calls the same pause, but hearing it needs a device.

## 2026-10-28T08:10:00Z — multiplayer match rules

- Goal: G08. Requirement: R17 in progress.
- Observed: duration is 1-10 minutes then five-minute steps to 60 or unlimited;
  the second selector is points (or lives for Top Agent) from 1-10 then
  five-point steps to 120. Arena and Team Arena score victories; the other
  scored modes use points. Team scores sum players' points.
- Evidence: `docs/MULTIPLAYER-INVENTORY.md`, from the rules page and score
  function.
- Verdict: rule ranges and scoring are source-complete. Match execution remains.

## 2026-10-28T08:25:00Z — media tolerance and region choice

- Goal: G07. Requirement: R08 in progress.
- Observed: the engine maps every level to an intro id, but the supply ships
  intros only for mission starts. The CastleExterior recording requests
  CastleCourtyard's missing movie, logs "cannot open", and still matches all
  5,649 frames.
- Observed: NightPad writes `Region=NTSC`, matching the shipped 30 fps movie
  bundle; a PAL run would request 25 fps files the image does not contain.
- Evidence: the recording log in ignored `build/` and the campaign inventory.
- Verdict: missing sub-level intros are safe, and NTSC is the correct region for
  this image. PAL media remains an external content gap.

## 2026-10-28T08:40:00Z — clean shell build

- Goal: G13. Requirement: R26 in progress.
- Observed: `build_ios_shell.sh` accepts `--clean`, and
  `test_clean_shell_build.sh` removes both build trees, then configures and
  builds simulator and device from scratch.
- Evidence: both lanes build and the link check passes with no loose engine
  dylibs.
- Verdict: the shell does not depend on incremental artefacts. The engine and
  dependency layers still come from cached builds; a full clean-checkout
  rebuild remains.

## 2026-10-28T08:50:00Z — full engine suite green

- Goal: G04/G12. Requirements: R05, R11 in progress.
- Observed: `scripts/verify_engine.sh` ran end to end at commit `3e7a133`:
  action and driving lifecycles, action pause with audio, assists, driving pause
  with audio, early stop, the three-cycle transition, the handoff and the
  action-driving-action round trip all pass.
- Evidence: the suite's own output; `engine verification: PASS`.
- Verdict: the engine layer is green as a whole, not only gate by gate. Device
  execution remains the acceptance step.

## 2026-10-28T09:05:00Z — repository privacy gate

- Goal: G00. Requirement: R27 in progress.
- Observed: the repository tracks 172 source files and no ref/build/vendor/
  evidence tree, retail image, movie, or binary artefact. The ignore rules the
  build relies on are present.
- Evidence: `scripts/check_privacy.sh`, now part of `verify_quick.sh`.
- Verdict: the private-data boundary is checked mechanically. Notices and
  licensing uncertainty remain documented in `docs/PROVENANCE.md`.

## 2026-10-28T09:20:00Z — candidate manifest draft

- Goal: G13. Requirement: R30 in progress.
- Observed: wrote `docs/CANDIDATE.md` with identity fields to record at freeze,
  the support matrix, verified evidence, known issues and the device next step.
  It states plainly that it is a draft and not an acceptance claim.
- Evidence: the document plus the linked gates and checklists.
- Verdict: the handoff shape exists. Final hashes, device results and candidate
  identity wait on acceptance.

## 2026-10-28T09:40:00Z — performance routes and budgets

- Goal: G12. Requirement: R24 in progress.
- Observed: wrote `docs/PERFORMANCE-BUDGET.md` before any device measurement:
  device state, 15-minute action and driving routes, warm repeats and a
  60-minute mixed session, with cadence (0.98-1.02), frame-time tail, memory
  ceilings, thermal expectation, input latency and audio budgets.
- Evidence: the document and the test-matrix row. All numbers are marked
  proposed until the first measured session.
- Verdict: the target is fixed enough to judge optimizations later. Nothing is
  measured on hardware yet.

## 2026-10-28T10:00:00Z — machine-generated candidate identity

- Goal: G13. Requirement: R30 in progress.
- Observed: `scripts/candidate_identity.sh` prints the commit, tree state,
  engine pin and vendor HEAD, dependency-lock hash, patch count and series hash,
  data identity and content hash, and the package hash when present. It fails if
  the vendor HEAD drifts from the pin, and `--require-clean` refuses an
  uncommitted tree.
- Evidence: a draft run produced the values now quoted in `docs/CANDIDATE.md`;
  they are labelled illustrative and must be regenerated at freeze.
- Verdict: freezing the candidate is mechanical. Final values wait on the last
  commit and device acceptance.

## 2026-10-28T10:20:00Z — performance log summarizer

- Goal: G12. Requirement: R24 in progress.
- Observed: `scripts/summarize_perf.py` parses the engine's PerfLog lines into
  JSON with mean/median/min/max fps, working and waiting milliseconds, and the
  requested cap. `--skip` drops loading samples; a log with no samples exits
  non-zero.
- Evidence: `scripts/test_perf_summary.sh` checks the maths, skip behaviour and
  empty-log failure; the tool also parses the existing host render-cost logs.
- Verdict: device captures will produce comparable records. Real measurements
  still need hardware.

## 2026-10-28T10:40:00Z — no network path in the app

- Goal: G00. Requirement: R27 in progress.
- Observed: `apple/` contains no `URLSession`, `NSURLConnection`, `CFStream`,
  `NWConnection`, `getaddrinfo` or socket call. The About page opens links in
  the browser; diagnostics write locally and leave only through the share sheet.
- Evidence: `scripts/check_privacy.sh` now fails on any of those APIs and runs in
  the quick pass; `docs/PROVENANCE.md` states the boundary.
- Verdict: the "no automatic upload" claim is checked mechanically.

## 2026-10-28T11:00:00Z — driving and mounted-view help split

- Goal: G06. Requirement: R13 in progress.
- Observed: the help page described one "Driving and turrets" mapping, but the
  eight POV configurations differ: camera spin is Y except on one mount (B),
  reload is A except on one (X), and secondary cycling moves between D-pad,
  White/Black and face buttons.
- Observed: the page now has separate Driving and Mounted views cards, with the
  common POV mapping and its variations named. The simulator accessibility tree
  lists every row.
- Evidence: `docs/DRIVING-CONTROLS.md`, the refreshed help page and its AX tree.
- Verdict: the help no longer implies one vehicle layout. In-game verification
  of each mount remains device work.

## 2026-10-28T11:20:00Z — background pause policy

- Goal: G12. Requirement: R16 in progress.
- Observed: the shell now pauses the engine on
  `UIApplicationDidEnterBackgroundNotification` and resumes on foreground, but
  only the pause it created. Native UI or the player's own pause is left alone,
  and the session log records both transitions.
- Evidence: `scripts/test_background_policy.sh` covers playing, stopped,
  already-held and manual-pause states; both shell lanes build.
- Verdict: the interruption rule is explicit and tested. Device suspension and
  audio behaviour still need a session.

## 2026-10-28T11:35:00Z — all pinned checkouts verified at freeze

- Goal: G13. Requirement: R30 in progress.
- Observed: the identity script previously checked only the engine pin. It now
  verifies every `source_graph` checkout — engine, GalaxyPad, SunPad,
  extract-xiso and the FFmpeg submodule — and fails on drift before printing an
  identity.
- Evidence: a draft run reports five `donor_ok` lines and correctly refuses a
  dirty tree.
- Verdict: freezing checks the whole dependency graph, not one pin.

## 2026-10-28T11:55:00Z — cancel no longer bricks imports

- Goal: G05. Requirement: R04 in progress.
- Observed: `GameDataImporter::Prepare` never cleared its cancel flag, so one
  cancel made every later import return "Import cancelled." until the app was
  relaunched. The shell also presented a cancellation as an error alert.
- Observed: a new Prepare now resets the flag as a fresh transaction. The test
  cancels mid-copy, confirms no stage remains, then prepares again with the same
  importer. The shell shows "Import cancelled" with "No game data was changed."
- Evidence: `scripts/test_data_import.sh` passes; both shell lanes build.
- Verdict: import cancellation is recoverable. Device picker selection remains
  manual.

## 2026-10-28T12:15:00Z — bot setup options

- Goal: G08. Requirement: R17 in progress.
- Observed: each of the six bot slots exposes playing, accuracy
  (poor-very good), aggression (normal-very high), speed (slow-fast), health
  50-300, reaction and recovery 50-200, and a personality list that depends on
  the bot's side. Characters at skin index 15 and above have fixed stats.
- Evidence: `docs/MULTIPLAYER-INVENTORY.md`, from the bot setup page.
- Verdict: the bot option surface is source-complete. Behaviour at six bots and
  team composition still need matches.

## 2026-10-28T12:30:00Z — older settings files keep working

- Goal: G06. Requirement: R12 in progress.
- Observed: the settings file gained render, FOV and assist keys over time. A
  version-1 file containing only the older keys now has a test proving its known
  values survive and the newer keys take their defaults.
- Evidence: `scripts/test_settings.sh` passes with the backward-compatibility
  case.
- Verdict: adding settings keys does not invalidate an existing profile.

## 2026-10-28T12:45:00Z — menu actions present their sheets

- Goal: G06. Requirements: R12 and R13 in progress.
- Observed: with a game preview on screen, tapping a three-dot menu action that
  presents a view controller did nothing. Touch Layout, Control Help, About,
  Diagnostics and Share Saves all dismissed the menu and left the screen
  unchanged, because UIKit ignores a presentation started in the same turn as
  the menu dismissal.
- Observed: those six call sites now go through `presentAfterMenu:`, which waits
  150 ms and skips when a controller is already presented. Informational and
  error alerts use the same route, so "No saves yet" and "Game data required"
  appear instead of being dropped.
- Observed: rebuilding the touch layout reset every view's alpha to 1 and
  cleared `accessibilityElementsHidden`, so controls hidden by the
  controller-hide policy flashed back and VoiceOver saw them. Both properties
  now follow the hidden state in `setTouchLayout:` and `setControlsHidden:`.
- Evidence: iPhone 17 simulator, iOS 26.5, `--preview-gameplay`. Controls >
  Touch Layout opens the editor (`evidence/ios-shell/menu-touch-layout.png`);
  Control Help, About and Info > Diagnostics open
  (`evidence/ios-shell/menu-diagnostics.png`); Game Data & Saves > Share Saves
  opens the system sheet with the two saves, and shows "No saves yet" when the
  folder is emptied. `scripts/verify_quick.sh` passes.
- Note: the first cell of a nested submenu cannot be hit through the
  simulator's accessibility bridge; its reported frame lands on the submenu
  header, which navigates back. The editor was opened with a direct tap on the
  cell instead.
- Verdict: menu actions reach their sheets during a running session. Physical
  device confirmation and an in-game save remain.

## 2026-10-28T13:05:00Z — the extra front-end headings are chapters, not missions

- Goal: G07. Requirement: campaign inventory.
- Observed: the text bank holds eighteen campaign headings with a description
  for each, but the wheel exposes twelve missions. The engine names eleven of
  the bank headings in `assets.h` and gives Countdown a separate id, so seven
  bank ids are never referenced: Training, Hidden Agenda, Streets of Tokyo,
  Atoll Infiltration, Island Caves, River Gauntlet and a duplicate "Countdown".
- Observed: each unused description names a beat the wheel missions cross - the
  plant's secret use, fleeing to Q's mobile headquarters, the Vanquish
  approach, the radar-jamming caves and the Disarmament Facility. The level
  table's three `Cut_Level` entries back that reading, and the supplied data
  has no separate atoll bundle.
- Evidence: `vendor/nightfire/src/action/ui/ui_nightfire.cpp`,
  `vendor/nightfire/src/action/assets.h`, `UKTxt.Dat` ids `0x03000000`-
  `0x03000023`; written up in `docs/CAMPAIGN-INVENTORY.md`.
- Verdict: the extra headings are chapters inside the twelve missions. NightPad
  keeps listing twelve starts. Per-mission start/end state and objectives
  remain open.

## 2026-10-28T13:35:00Z — mission parts and objectives inventoried

- Goal: G07. Requirement: campaign inventory.
- Observed: `MissionData` lists 24 action level parts with their base map and
  order, and each part's objective array. Resolving those ids through the text
  dump gives the objectives for every action mission, including the four-part
  Castle, Henderson, Tower and Tower 2 chains.
- Observed: the two out-of-wheel base maps confirm the earlier cut-chapter
  reading. `Cut_Level1` and `Cut_Level2` hold the power-plant security
  objectives for "Hidden Agenda", with a placeholder in part two;
  `Cut_Level3`'s array is named `Caves` and holds three placeholders for
  "Island Caves".
- Observed: the five driving missions have no `MissionData` rows, so their
  objectives are engine-side and still open.
- Evidence: `vendor/nightfire/src/action/game/sp/Mission.cpp` and `UKTxt.Dat`
  ids `0x04000000`-`0x04000069`; the paraphrased table is in
  `docs/CAMPAIGN-INVENTORY.md`.
- Verdict: objectives are inventoried for all nine action missions. Start/end
  state per part, saves and the driving objectives remain.

## 2026-10-28T13:50:00Z — part start and end state

- Goal: G07. Requirement: campaign inventory.
- Observed: `Mission_Init` resets only the loaded part's objectives, hidden or
  not shown by channel, and resets player stats only when the level is the
  mission's first part; a warm reset leaves earlier parts alone.
- Observed: winning sets the mission-won channel. The final parts end to their
  outro level (CastleIndoors2, HendersonD, TowerC, PowerStationA2, Tower2C,
  EvilBaseC, SpaceStationD, Cut_Level2); other parts hand off through their own
  level scripts. Failure is per channel - alarm, civilian killed, Kiko escaping,
  missile launched - plus death, and every failure route opens the mission-end
  menu.
- Evidence: `vendor/nightfire/src/action/game/sp/Mission.cpp` (`Mission_Init`,
  `Mission_Update`, `Mission_GetEndTo`); written up in
  `docs/CAMPAIGN-INVENTORY.md`.
- Verdict: the part lifecycle is documented from source. Which part writes a
  save, and the driving-mission objectives, still need evidence.

## 2026-10-28T14:05:00Z — mission saves happen at the results page

- Goal: G07. Requirement: campaign inventory.
- Observed: no level part saves. The results page sets `LS_OPERATION_SAVE`
  with `SAVE_ALL` when the player continues past it, so a completed mission is
  written then; failure and death never reach that page, so the run is lost.
- Evidence: `vendor/nightfire/src/action/ui/ui_nightfire.cpp` (results handler),
  `vendor/nightfire/src/action/ui/ui_codenames.cpp` (save operation),
  `vendor/nightfire/src/action/engine/LoadSave.cpp`.
- Verdict: the save question for action missions is answered. Driving-mission
  objectives remain the last open inventory item.

## 2026-10-28T14:20:00Z — touch controls can be hidden like GalaxyPad's

- Goal: G06. Requirement: R12 in progress.
- Observed: the layout model already stored a `visible` flag and the overlay
  already skipped hidden controls, but the editor offered no way to set it.
  GalaxyPad's in-game editor has a visibility toggle, so this was a parity gap.
- Observed: long-pressing a control now offers Hide Control or Show Control.
  Hidden controls stay visible while editing, dimmed with a brighter outline and
  the value "Hidden" for VoiceOver, so they can be turned back on. The hint line
  names the gesture.
- Evidence: iPhone 17 simulator, iOS 26.5: hiding the left stick, saving and
  relaunching with `--show-touch-controls --preview-gameplay` left
  `nightpad.touch.left_stick` out of the live overlay; Show Control and Save
  restored it. `scripts/test_touch_layout.sh` now also proves the flag survives
  save and load, and `scripts/verify_quick.sh` passes. Evidence
  `evidence/ios-shell/touch-layout-hidden.png`.
- Verdict: hiding a control is end-to-end and reversible. Physical ergonomics
  and the in-game overlay on a device remain.

## 2026-10-28T14:35:00Z — candidate identity and package refreshed

- Goal: G13. Requirement: R29/R30 draft.
- Observed: `scripts/candidate_identity.sh --require-clean` passes on the current
  tree: all five pinned checkouts match, the tree is clean, 17 patches still
  reproduce 53 files, and the data identity is unchanged.
- Observed: `scripts/package_device_app.sh` rebuilt the unsigned IPA from that
  tree. New SHA-256
  `af8b1cd031a5d4e5cc048841fb978281609c5bc4e3ed9bcb35891bb057aa78c7`; the
  earlier draft's `6f1f9667…` package predates the menu and editor changes.
- Evidence: `docs/CANDIDATE.md` snapshot, `build/package/NightPadShell-unsigned.ipa`.
- Verdict: the draft manifest now points at the tree that is actually current.
  Final freeze still waits on device acceptance.

## 2026-10-28T14:50:00Z — tablet layout checked on an iPad

- Goal: G06. Requirement: R12 in progress.
- Observed: on the iPad Pro 13-inch simulator the editor opens from the
  three-dot menu - so the deferred menu presentation works with iPad's popover
  menu as well - and shows the tablet defaults: shoulders across the top,
  triggers top corners, face buttons clustered on the right.
- Observed: the live overlay renders the same tablet layout, and every control
  keeps its identifier, so the accessibility tree is unchanged between phone and
  tablet apart from position.
- Evidence: `evidence/ios-shell/ipad-touch-overlay.png`;
  `scripts/test_touch_layout.sh` now also asserts that the device name selects
  `layout-phone.txt` or `layout-tablet.txt`.
- Verdict: tablet layout and overlay are verified visually. Saving from the
  iPad's form sheet could not be driven through this harness - taps in its
  navigation bar land on the sheet's dismiss region - so tablet persistence and
  drag editing stay open.

## 2026-10-28T15:05:00Z — one-tap import from the app folder

- Goal: G05. Requirement: R04 in progress.
- Observed: the only import path was the system folder picker, whose remote UI
  cannot be scripted, so every import test and every tablet import needs manual
  navigation. SunPad offers a folder inside its own app storage instead.
- Observed: Game Data & Saves now has "Import from NightPad Folder", which
  imports `Documents/NightPad Import` and says where to put it when the folder is
  missing. Both import paths now open the data panel before starting, so the
  progress bar and Cancel Import are visible; the cancel button hides again when
  the import ends.
- Evidence: re-imported the 1.9 GB prepared tree through the new action on the
  iPhone 17 simulator, from "Copying prepared game data" with a live bar to
  "Game data imported"; identity stayed `data-a3c98ab965ac41e559ac` and both
  saves were byte-identical. `scripts/verify_quick.sh` passes. Evidence
  `evidence/ios-shell/import-from-folder.png`.
- Verdict: import no longer depends on the picker. Choosing a folder from
  outside the app still needs the picker and remains manual.

## 2026-10-28T15:20:00Z — texture overrides decided

- Goal: G11. Requirement: R21 decision.
- Observed: the engine's DDS replacement (`textureReplace.cpp`) is part of the
  D3D9 backend, which this target does not compile. The SDL GPU backend's own
  header lists replacement and dumps as not carried over; the built action
  binary exports no `TextureReplace` symbols, and a headless run with
  `DumpTextures=1` produced no dump folder and no log line.
- Observed: the public Nightfire modding scene targets the PC, PS2 and Dolphin
  builds (BSP decompiler, GearCraft, editor suites, HD texture work). No Xbox
  texture injector or packaged Xbox texture pack was found, and upstream's own
  extraction notes say `filesys.dxx` is not fully unpacked.
- Evidence: `docs/DECISIONS/0013-texture-overrides.md`;
  `vendor/nightfire/src/common/gfx/sdlGpuBackend.cpp`;
  `vendor/nightfire/src/common/gfx/textureReplace.cpp`; the headless
  `DumpTextures=1` run.
- Verdict: R21 decided - inventory complete, bounded SDL/Metal prototype
  deferred with a four-step plan recorded. No texture mods are advertised.

## 2026-10-28T15:45:00Z — foundation and regression records filled

- Goal: G00/G04. Requirements: R01 and R28.
- Observed: both requirement records were empty. R01's evidence already
  existed: the reconstructed action and driving engines are the game's own code
  from the pinned revision, patched only for the Apple port, with the supplied
  Xbox image and both XBEs as the game itself; campaign and multiplayer systems
  are preserved and inventoried, with runtime acceptance kept under R09/R17.
- Observed: `scripts/verify_engine.sh` passed in full on commit `480ac5a` - all
  nine gates including pause with audio, assists, transitions, handoff and the
  round trip - and `scripts/verify_quick.sh` covers the host tests, both shell
  lanes, link contract, patch provenance and privacy. Device-only scenarios and
  the missing PAL media are listed in `docs/TEST-MATRIX.md` rather than
  assumed.
- Evidence: `config/goal-state.json`, `docs/TEST-MATRIX.md`,
  `scripts/verify_engine.sh`, `scripts/verify_quick.sh`.
- Verdict: R01 and R28 pass for their stated scopes. Device gates stay where
  they are.

## 2026-10-28T16:00:00Z — import, cheats, diagnostics and provenance records closed

- Goal: G05/G10/G12. Requirements: R04, R20, R25, R27.
- Observed: these records still read unverified or in progress although the
  work and its evidence exist. Import has host coverage for preflight, staging,
  validation, cancellation, atomic activation, replacement and rollback, plus
  two shell paths with progress and cancel and byte-identical saves.
- Observed: the cheat audit has a per-option decision - immortality and
  unlimited ammo exposed and excluded from acceptance runs, all-weapons
  deferred on a concrete live-player blocker, unlock-everything rejected - and
  diagnostics are local, redacted and distinguish diagnostic from performance
  builds.
- Observed: donor notices, pins and the upstream license question are in
  PROVENANCE/UPSTREAM-DELTA, and the privacy gate fails on retail trees or any
  networking API in the app.
- Evidence: `docs/TEST-MATRIX.md`, `docs/CHEATS-RESEARCH.md`,
  `docs/PROVENANCE.md`, `scripts/test_data_import.sh`,
  `scripts/test_release_diagnostics.sh`, `scripts/check_privacy.sh`.
- Verdict: R04, R25 and R27 pass; R20 is decided. The picker's manual folder
  choice and device-only scope notes stay as stated.

## 2026-10-28T16:15:00Z — the data panel offers both import paths

- Goal: G05. Requirement: R04.
- Observed: the one-tap folder import existed only in the three-dot menu, while
  the panel's prominent button still forced the system picker. GalaxyPad's
  settings and SunPad's data page both put their own-folder path next to the
  picker.
- Observed: the panel's import button is now a small menu - "Choose a Folder…"
  and "Use NightPad Folder" - so the picker and the app-folder path sit
  together. Importing from the panel shows the same progress, cancel and
  completion alert.
- Evidence: iPhone 17 simulator, iOS 26.5: panel > Use NightPad Folder ran the
  1.9 GB re-import to `data-a3c98ab965ac41e559ac` and finished with "Game data
  imported"; Cancel Import hid again afterwards.
- Verdict: both import paths are reachable from the panel. Choosing an
  arbitrary external folder still uses the picker.

## 2026-10-28T16:35:00Z — data survives an app update

- Goal: G05. Requirement: R11 in progress.
- Observed: reinstalling the app over itself - the simulator's equivalent of an
  update - moved the app to a new data-container UUID yet kept every file:
  `slot1.sav`, `settings.txt` and `layout-phone.txt` were byte-identical
  (SHA-256 compared before and after), the imported tree still reported ready
  as `data-a3c98ab965ac41e559ac`, and the Controls menu showed the persisted
  auto-hide and rumble choices.
- Evidence: iPhone 17 simulator, iOS 26.5; hashes recorded in the run and the
  row added to `docs/TEST-MATRIX.md`.
- Verdict: app updates keep saves, settings, layouts and imported data.
  Interrupted engine writes and a signed store update remain open.

## 2026-10-28T16:50:00Z — save restore verified, and atomic

- Goal: G05. Requirement: R11 in progress.
- Observed: save restore deleted the destination before copying, so an
  interruption could leave a missing or half-written slot. It now writes the
  bytes atomically through `NSDataWritingAtomic`.
- Observed: the restore path had no automated input because the picker's remote
  UI is not scriptable. A `--restore-saves-fixture` launch hook feeds
  `Documents/SaveFixture` into the same `restoreSaves:` call, so the collision
  prompt and replacement are exercisable.
- Evidence: iPhone 17 simulator, iOS 26.5: a 32-byte `slot1.sav` and an 8-byte
  `newslot.sav` for the fixture - the app asked to replace the existing slot,
  reported "2 files restored", wrote both contents exactly and left the
  unrelated codename file untouched. `evidence/ios-shell/save-restore.png`.
- Verdict: save restore and replacement are verified and atomic. Picking files
  from outside the app stays manual, and an interrupted engine write still
  needs a device run.

## 2026-10-28T17:05:00Z — handoff checklist matches the app

- Goal: G13/R30. Requirements: R26, R30 in progress.
- Observed: the device checklist still described the picker as the import path,
  did not mention the hide/show gesture or the save-restore prompt, and carried
  the previous package hash.
- Observed: the checklist now names the app-folder import first, adds a
  save-restore session, mentions hiding a control, records what the device pass
  cannot expect (texture overrides) and carries the rebuilt package hash.
- Evidence: `docs/DEVICE-HANDOFF.md`; `scripts/package_device_app.sh` rebuilt the
  unsigned IPA at `f46e4e9`,
  sha256 `4ff2f289ce0c62a4d88d25efde1a6a03fbaf9bdbb9fa95578aab65f8e9e9695e`;
  `docs/CANDIDATE.md` snapshot updated to the same values.
- Verdict: the handoff document describes the app that exists. Final freeze
  still waits on device acceptance.

## 2026-10-28T17:20:00Z — save restore from the app folder

- Goal: G05. Requirement: R11 in progress.
- Observed: restoring saves still depended on the system picker while importing
  game data no longer did. The same asymmetry existed on a tablet, where the
  picker is the clumsier surface.
- Observed: Game Data & Saves now has "Restore Saves from NightPad Folder",
  which restores everything in `Documents/Save Import` through the same
  `restoreSaves:` path, collision prompt included. The fixture hook now just
  points at a different folder.
- Evidence: iPhone 17 simulator, iOS 26.5: a 40-byte `slot1.sav` and a 6-byte
  `extra.sav` in the folder produced the replace prompt, "2 files restored",
  exact contents on disk and an untouched codename file.
- Verdict: both save paths are reachable without the picker. The picker path
  and interrupted engine writes remain as stated.

## 2026-10-28T17:35:00Z — clean rebuild and package at the current commit

- Goal: G13. Requirements: R26, R30 in progress.
- Observed: `scripts/test_clean_shell_build.sh` configured and built both lanes
  from empty build trees, and the link check still finds the action and driving
  engine symbols with no loose SDL, FFmpeg or SPIRV dylibs.
- Observed: `scripts/package_device_app.sh` then rebuilt the unsigned IPA at
  `5b8583a`; the previous package predated the save-restore folder work.
- Evidence: `scripts/test_clean_shell_build.sh` PASS;
  `build/package/NightPadShell-unsigned.ipa` sha256
  `cecc2e029820db350a804897e7abf5f1eb1c1f87d0985f909f952483449e3a29`;
  `docs/DEVICE-HANDOFF.md` and `docs/CANDIDATE.md` updated.
- Verdict: the build and package recipes reproduce from a clean shell tree.
  Signing/install and a full clean engine/dependency rebuild remain.

## 2026-10-28T17:55:00Z — startup errors are no longer lost

- Goal: G06. Requirement: R12/R25.
- Observed: with a bad `settings.txt` and a bad touch layout, the app started on
  defaults but could drop one of the two errors: the presentation ran before
  the view was in a window, and a second presentation was skipped while the
  first was up.
- Observed: `presentAfterMenu:` now retries briefly until the view has a window
  and lets alerts stack on the alert that is already up; sheets still wait for
  the top of the stack. Both errors now appear, one after the other, and the
  app keeps working on defaults.
- Evidence: iPhone 17 simulator, iOS 26.5: `version=99` settings and an
  unsupported layout header produced "Saved touch layout ignored" over "Saved
  settings ignored" with no crash; restoring both files gave a clean launch.
- Verdict: a corrupt profile or layout is reported and survivable.

## 2026-10-28T18:15:00Z — the eight action schemes are mapped

- Goal: G06. Requirement: R13 in progress.
- Observed: `psiInput.cpp` fills 19 action channels for each of the eight
  controller styles, so the schemes can be compared exactly. Nightfire is the
  baseline; Moonraker moves crouch and reload; Octopussy, Thunderball and
  Classic Bond swap the horizontal sticks; Dr. No is fully southpaw with
  D-pad jump and crouch; Goldfinger and GoldenEye move alternate fire and the
  cycling buttons, and Dr. No and Goldfinger move night vision off Back.
- Observed: the Control Help intro now names the eight schemes the game offers,
  so a player knows what the original Controller Setup page will list.
- Evidence: `docs/CONTROL-SCHEMES.md`, from `src/action/engine/psiInput.cpp` and
  the scheme labels in `docs/ui/handlers.md`; the help page read back from the
  iPhone 17 simulator shows the sentence.
- Verdict: the action schemes are mapped and described. Device passes per
  scheme, and the physical pad driving the same channels, remain.

## 2026-10-28T18:30:00Z — the driving objective text is located

- Goal: G07. Requirement: campaign inventory.
- Observed: the driving HUD takes its objective line from `objectiveMsgId` in
  the driving locale table, and the table ships inside `driving/misc.viv` as
  `data/gfx/locale/IDL_ENG.loc`. It is a `LOCH` header plus a `LOCI` index of
  1530 big-endian offsets into NUL-terminated strings, and it extracts with the
  BIGF/RefPack reader the control inventory already has.
- Observed: what remains is attribution - the mission picks the text from
  track event data - so a per-mission list still needs a track parser.
- Evidence: `docs/CAMPAIGN-INVENTORY.md`; the extracted locale file stays in
  ignored output and no retail strings were added to the repository.
- Verdict: the last G07 inventory item has a concrete path and a concrete
  remaining step, rather than a vague gap.

## 2026-10-28T18:45:00Z — known issues collected

- Goal: G13/R30. Requirement: R30 in progress.
- Observed: the candidate's open issues were spread across STATUS, the test
  matrix, the decision records and requirement notes, which makes the handoff
  read as complete when it is not.
- Observed: `docs/KNOWN-ISSUES.md` now lists each open issue with its effect
  and where the detail lives, and separates the things that look like bugs but
  are expected: the black simulator preview, the submenu accessibility quirk
  and the patch whitespace warning.
- Evidence: `docs/KNOWN-ISSUES.md`, linked from `docs/CANDIDATE.md` and
  `docs/STATUS.md`.
- Verdict: the candidate has an explicit known-issues document. The freeze
  still needs device acceptance.

## 2026-10-28T19:20:00Z — headless driving does not reach objectives

- Goal: G07. Requirement: campaign inventory.
- Hypothesis: logging `objectiveMsgId` when the HUD draws it would attribute
  the locale strings to missions without a track parser.
- Observed: with a temporary `NIGHTPAD_LOG_OBJECTIVES` print in
  `DrawObjectiveMessage`, Mission 1 loaded Paris and ran at 50 fps for a long
  cycle, but the hook never fired - the car does not move under the lifecycle
  test, so the objective events never post. The hook was reverted and
  `scripts/verify_patches.sh` still reproduces the 53 files.
- Evidence: the captured run log and `docs/CAMPAIGN-INVENTORY.md`.
- Verdict: attribution needs the track parser or a driven run. A headless
  boot alone cannot answer it.

## 2026-10-28T19:40:00Z — throttle does not reach the first objective either

- Goal: G07. Requirement: campaign inventory.
- Hypothesis: holding full throttle through the host-pad hook would start the
  Paris route and post the first objective.
- Observed: two runs, thirty and ninety seconds, with the right trigger held
  and the objective log enabled, produced no `[objective]` line. The mission
  loads and renders, but it is still in its intro or waiting state, so the
  track events never post. Both the log hook and the throttle hold were
  reverted; `scripts/verify_patches.sh` still reproduces the 53 files.
- Evidence: the captured run logs and `docs/CAMPAIGN-INVENTORY.md`.
- Verdict: a headless boot, with or without throttle, cannot attribute the
  driving objectives. The track parser or an interactive run is required.

## 2026-10-28T20:10:00Z — controls can be made fainter

- Goal: G06. Requirement: R12 in progress.
- Observed: the layout model and file format carry an opacity per control, and
  the overlay uses it, but the editor never exposed it - every control stayed at
  the 70% default.
- Observed: long-pressing a control now shows Hide Control and an Opacity
  submenu (30, 50, 70, 100%) with the current value ticked. The change applies
  to the view immediately and to the live overlay after Save.
- Evidence: iPhone 17 simulator, iOS 26.5: 30% dimmed the left stick in the
  editor and the overlay, `layout-phone.txt` held `0.3`, and restoring the saved
  70% layout brought the stick back. Evidence `evidence/ios-shell/touch-opacity.png`.
- Verdict: opacity is reachable and persisted. Physical readability over a
  bright scene remains a device check.

## 2026-10-28T20:30:00Z — a swiped-away sheet no longer strands the pause

- Goal: G06. Requirement: R15 in progress.
- Observed: the shell marks native UI as open before presenting an editor or
  reference sheet and only clears it from the sheet's own close handler. A
  sheet dismissed interactively never calls that handler, so on iPad the game
  would stay flagged paused with input suspended until another sheet closed.
- Observed: the shell now becomes the presentation delegate for the sheets it
  presents. `presentationControllerDidDismiss:` reloads the saved touch layout
  (so unsaved changes are dropped, as Cancel does) and ends native UI.
- Evidence: iPad Pro 13-inch simulator, iOS 26.5: dismissing the Touch Layout
  form sheet with its dismiss affordance logged `native UI resume` in the
  diagnostics session events and returned to the home screen; before the
  change no such event was produced.
- Verdict: an interactively dismissed sheet leaves the shell in its normal
  state. The paused-engine case still needs a device run with the game live.

## 2026-10-28T20:45:00Z — the data panel shows its state

- Goal: G05. Requirement: R04 in progress.
- Observed: the home screen's "Game data ready" or "missing" label sits
  centred behind the data panel, so the panel that manages data hid the only
  status line the player could use.
- Observed: the panel now carries its own status - Ready with the identity,
  Needs attention, or No game data imported - directly above the import button.
- Evidence: iPhone 17 simulator, iOS 26.5, `--open-data`: the panel shows
  "Ready · data-a3c98ab965ac41e559ac". Evidence
  `evidence/ios-shell/panel-status.png`.
- Verdict: the panel is self-contained. The longer identity wraps to two lines,
  which the card has room for.

## 2026-10-28T20:55:00Z — no duplicate status behind the panel

- Goal: G05. Requirement: R04 in progress.
- Observed: with the panel's own state line in place, the home status label
  could still be seen through the slightly translucent card, reading "Game data
  ready" behind the import button.
- Observed: `openDataPanel` hides the home label and `closePanels` restores it
  according to the gameplay mode, so only one status line is visible at a time.
- Evidence: iPhone 17 simulator, iOS 26.5, `--open-data`; the refreshed
  `evidence/ios-shell/panel-status.png` shows a clean card.
- Verdict: the panel reads as one surface. Nothing else changes.

## 2026-10-28T21:10:00Z — saves belong to the data panel too

- Goal: G05. Requirement: R11 in progress.
- Observed: the panel is called "Game Data & Saves" but only handled game
  data; Share Saves and Import Saves lived solely in the three-dot menu.
- Observed: the panel now has Share Saves and Restore Saves beside the import
  actions. Share opens the system sheet with the two saves; Restore with no
  `Documents/Save Import` folder says where to copy files. Restoring is refused
  while the engine runs, matching the menu item's rule.
- Evidence: iPhone 17 simulator, iOS 26.5, `--open-data`;
  `evidence/ios-shell/panel-saves.png`.
- Verdict: the panel matches its name. The running-engine refusal shares the
  existing message and still needs a live-engine run for evidence.

## 2026-10-28T21:25:00Z — restore from the panel offers both sources

- Goal: G05. Requirement: R11 in progress.
- Observed: the panel's Restore button only used `Documents/Save Import`, while
  the import button next to it offered both the picker and the app folder.
- Observed: Restore is now a menu - "Choose Files…" opens the system picker,
  "Use Save Import Folder" uses the folder - so the two rows behave alike.
- Evidence: iPhone 17 simulator, iOS 26.5: both menu items appear, the folder
  one gives the "No save folder" explanation, and the picker opens (its remote
  UI is still not scriptable).
- Verdict: the panel's save and data rows are symmetric. Picker selection stays
  manual.

## 2026-10-28T21:40:00Z — only real resumes reach the session log

- Goal: G06. Requirement: R25 in progress.
- Observed: `endNativeUI` logged "native UI resume" even when nothing had been
  paused, so opening and closing About on the home screen looked like a resume
  in diagnostics. The dismissal path also relied on that event as its only
  trace.
- Observed: the resume event is now written only when input suspension or the
  UI pause was actually held, and interactive dismissal logs its own
  "sheet dismissed" event.
- Evidence: iPad Pro 13-inch simulator, iOS 26.5: dismissing the editor logged
  "sheet dismissed" and no resume; the iPhone home screen showed only
  "app launch" after opening and closing About.
- Verdict: the diagnostics session history matches what happened. Engine-
  paused resumes still need a device run to be observed.

## 2026-10-28T22:00:00Z — the package is checked, not just built

- Goal: G13. Requirement: R26 in progress.
- Observed: `package_device_app.sh` produced an IPA and rejected loose dylibs,
  but nothing asserted what the bundle actually contains or links.
- Observed: `scripts/check_package.sh` now unpacks the IPA and checks exactly
  three app entries, an arm64 executable, libraries only from `/System/Library`
  or `/usr/lib`, a 16.0 minimum, landscape-only orientations and file sharing.
  The package script runs it last, so a bad package fails the build.
- Evidence: `scripts/check_package.sh` PASS on the rebuilt package
  (`aea72924…f52839b22b2`), which is now the hash in `docs/DEVICE-HANDOFF.md`
  and `docs/CANDIDATE.md`.
- Verdict: packaging has a content gate. Signing and installation remain the
  device handoff.

## 2026-10-28T22:20:00Z — text scales with Dynamic Type

- Goal: G13. Requirement: R29 in progress.
- Observed: several labels used a preferred font but never opted into
  `adjustsFontForContentSizeCategory`, so the data panel heading and detail, the
  progress line, the pause card and the diagnostics notice stayed fixed while
  the rest of the app grew.
- Observed: those labels now opt in, and the pause card's secondary line had no
  dynamic font at all; it now uses the subheadline style.
- Evidence: iPhone 17 simulator, iOS 26.5, content size extra-extra-large: the
  data panel's heading, detail, state and button titles all grow and the card
  still fits; About keeps its content in a scroll view. Evidence
  `evidence/ios-shell/panel-dynamic-type.png`.
- Verdict: the shell follows the system text size. The pause card needs a live
  engine to be seen at any size.

## 2026-10-28T22:45:00Z — old import stages no longer pile up

- Goal: G05. Requirement: R04 in progress.
- Observed: a re-import swaps the new tree in place and leaves the replaced
  one in that import's stage folder. Only the newest is reachable through
  "Remove Previous Game Data", and only until relaunch, so repeated imports had
  left four `GameData.import-*` trees - about 7.6 GB - that nothing could see.
- Observed: `GameDataImporter::CleanupAbandonedStages` removes stage-shaped
  directories that are neither the active stage nor the retained previous tree,
  and the shell calls it before reporting state at launch.
- Evidence: the simulator's Application Support fell from about 9.5 GB to
  1.9 GB, the active tree still reports ready as
  `data-a3c98ab965ac41e559ac` and saves were byte-identical.
  `scripts/test_data_import.sh` proves stage folders go and lookalikes stay.
- Verdict: repeated imports no longer leak disk. The rollback tree is now
  explicitly a same-session affordance, which KNOWN-ISSUES records.

## 2026-10-28T23:00:00Z — old identities go too

- Goal: G05. Requirement: R04 in progress.
- Observed: the stage cleanup covered `GameData.import-*`, but importing
  different content leaves the *old* `GameData/data-<identity>` tree beside the
  new one, with nothing reachable after relaunch.
- Observed: `RetainOnlyIdentity` removes identity-shaped directories other than
  the active one, called once at launch after the state is known. A retained
  previous tree stays for the current session, so the discard button still works.
- Evidence: `scripts/test_data_import.sh` creates a keep and an old identity tree
  and asserts the right one survives; the simulator still reports ready as
  `data-a3c98ab965ac41e559ac`.
- Verdict: both kinds of leftover tree are bounded now. The same-session
  retention is unchanged.

## 2026-10-28T23:15:00Z — cleanup no longer blocks the first frame

- Goal: G05. Requirement: R04 in progress.
- Observed: the cleanup ran on the main thread inside `refreshDataState`. With
  several full trees to delete that is seconds of I/O before the first frame on
  a phone.
- Observed: the launch cleanup now runs on a utility queue with its own
  importer, which has nothing active to protect; the per-refresh call is gone.
  The retained previous tree is still kept for the current session.
- Evidence: iPhone 17 simulator, iOS 26.5: planted stage and old-identity
  folders were both gone within three seconds while the home screen already
  reported ready.
- Verdict: cleanup is invisible at launch. The device will show whether a large
  delete still perturbs storage I/O during play.

## 2026-10-28T23:30:00Z — the status page matches the app

- Goal: G13. Requirement: R30 in progress.
- Observed: `docs/STATUS.md` still said the outcome was "G02 working baseline,
  G03 blocked" with a timestamp from the morning, and its next-step list still
  offered per-mission details that are now done while the driving attribution is
  the open one.
- Observed: the outcome now names the missing PAL set, the passing host engine
  suite and the simulator-verified shell, and the next step points at the data
  import and save round trip in the handoff plus the track-parser item.
- Evidence: `docs/STATUS.md`.
- Verdict: the status page describes the current tree. No code changes.

## 2026-10-29T00:00:00Z — monospaced text scales too

- Goal: G13. Requirement: R29 in progress.
- Observed: the home title, the About title and the diagnostics report used
  fixed `monospacedSystemFontOfSize:` fonts, so `adjustsFontForContentSizeCategory`
  had nothing to scale them from and they stayed put at XXL.
- Observed: all three now go through `UIFontMetrics` with a text style, so the
  title and the report grow with the system size.
- Evidence: iPhone 17 simulator, iOS 26.5 at extra-extra-large: the diagnostics
  report and notice are large and the page scrolls; evidence
  `evidence/ios-shell/diagnostics-dynamic-type.png`.
- Verdict: no fixed-size text is left in the shell. The pause card still needs a
  live engine to inspect.

## 2026-10-29T00:15:00Z — the event hook reaches nothing either

- Goal: G07. Requirement: campaign inventory.
- Hypothesis: `ESetObjective_MakeEvent_Callback` runs when the track builds its
  event objects at load, so logging the record's comment id would list the
  objectives without playing.
- Observed: a 25-second boot with that hook printed no objective record - the
  track does not create those events until the mission reaches the stage that
  uses them. The hook was reverted and `scripts/verify_patches.sh` still
  reproduces the 53 files.
- Evidence: the captured run log and the updated note in
  `docs/CAMPAIGN-INVENTORY.md`.
- Verdict: three headless routes have now been tried and ruled out. Only the
  track parser or an interactive run remains.

## 2026-10-29T00:40:00Z — why the headless driving run is slow

- Goal: G07. Requirement: campaign inventory.
- Observed: extending the event-creating hook's run to 180 seconds still showed
  no objective record. The longer log explains the budget: the direct `-mission`
  boot takes the EU default video mode and asks for `PAL\eng\paris_intro.mad`,
  which the 30 fps image does not contain, so the main loop only starts around a
  minute in.
- Observed: passing `-ntsc` does not help, because the video mode is fixed from
  the launch page before the game parses its own arguments; the app's handover
  page is already NTSC, so this is a harness default.
  The hook was reverted and `scripts/verify_patches.sh` reproduces the 53 files.
- Verdict: a direct boot cannot sit through the intro quickly enough to be a
  practical route. The track parser or an interactive device run stands.

## 2026-10-29T01:00:00Z — the track parser exists, and Paris has no comment text

- Goal: G07. Requirement: campaign inventory.
- Observed: a track's `.crp` is a `CARP` group tree with 16-byte records; the
  `Map ` group holds 114 mission rules, each with a reference to an `elNN` event
  list, and those lists carry the objective, waypoint and message events.
- Observed: `scripts/inspect_driving_track.py` parses that tree, lists the map's
  data families and decodes the rule event types. On Paris it finds the
  `ESetObjective` events, but all of their comment words are zero, so this
  mission's objective text comes from another event family.
- Evidence: the tool's output on Paris (`map group at 0x1f00`, 114 rules, 1391
  event lists) and `docs/CAMPAIGN-INVENTORY.md`. No retail strings are printed
  or committed.
- Verdict: the track data is readable now, which turns the attribution into
  decoding the right event family rather than parsing the container. The
  per-mission list is still open.

## 2026-10-29T01:30:00Z — the driving text lives in the loading screens

- Goal: G07. Requirement: campaign inventory.
- Observed: scanning every driving track settles the objective question - only
  Paris has `ESetObjective` events, all with a zero comment, and the others
  have none. The missions' description and hints are named by their loading
  screen layouts instead: `DESC_ID` plus one of `HINT_ID1..` per launch.
- Observed: the five missions' ids are 2800/2803 (Paris), 2900/2902-2908
  (Alpine), 3000/3005-3008 (Enemies Vanquished), 2650/2661-2672 (Deep
  Descent) and 2753/2770-2771 (Island Infiltration). They go through the locale
  file's indexed ids, so they do not match the string table's numbering.
- Evidence: `data/loading/*.ini` from `misc.viv` and
  `docs/CAMPAIGN-INVENTORY.md`; the strings themselves stay in the game data.
- Verdict: the mission-to-text mapping is known. Resolving the ids needs the
  `.loc` index decoded, which is the remaining step for paraphrased text.

## 2026-10-29T02:00:00Z — the driving missions' goals, paraphrased

- Goal: G07. Requirement: campaign inventory.
- Observed: a temporary print in `InitLoadScreen` resolved each mission's
  description and every `HINT_IDn` through the engine's own locale lookup, so
  the `.loc` index does not need decoding for this.
- Observed: the five driving missions' goals are protecting Dominique (Paris),
  leaving Drake's castle grounds (Alpine), reaching Q at extraction (Enemies
  Vanquished), getting past the island's defences (Deep Descent) and taking
  those defences apart (Island Infiltration), each with two to seven hints.
- Evidence: five headless boots with the print enabled; the hook was removed,
  `scripts/verify_patches.sh` reproduces the 53 files, and
  `docs/CAMPAIGN-INVENTORY.md` carries paraphrases only - no retail strings.
- Verdict: every driving mission now has a goal and hint summary. G07's
  inventory is complete except the first-play route, which is device work.

## 2026-10-29T02:20:00Z — the data tools now run in the gate

- Goal: G03. Requirement: R03 in progress.
- Observed: `tests/test_data_tools.py` covered the disc listing, the BIGF and
  RefPack readers, but nothing ran it; it was outside `verify_quick.sh`.
- Observed: the track inspector had no test at all. The test file now builds a
  synthetic CARP document - root, `Map ` group, one rule, one `elNN` list with
  an `ESetObjective` event - and checks that the inspector finds the map, reads
  both data items and decodes the event.
- Evidence: `scripts/test_data_tools.sh` passes (eight tests) and
  `scripts/verify_quick.sh` now runs it.
- Verdict: the tools the inventory relies on are under test. The real-data
  behaviour still needs the owner's image, which the tests never touch.

## 2026-10-29T02:40:00Z — the pause card can be seen without an engine

- Goal: G06. Requirement: R15 in progress.
- Observed: the App Pause card is only reachable while the engine runs, so its
  layout and Dynamic Type sizing were the last shell surface never inspected.
- Observed: a `--open-pause` launch hook, like the other deterministic screen
  hooks, shows the card directly. It renders correctly at the default size and
  at extra-extra-large, and the home status label is now hidden under the card
  as it already was under the data panel.
- Evidence: `evidence/ios-shell/pause-panel.png`.
- Verdict: every native surface has a screenshot. The card's behaviour with a
  live engine still needs the device.

## 2026-10-29T03:20:00Z — one command for the freeze

- Goal: G13. Requirement: R30 in progress.
- Observed: freezing the candidate meant remembering the right order of
  `verify_quick`, `verify_engine`, `candidate_identity` and `package_device_app`,
  and the package hash in the identity only matched if packaging happened first.
- Observed: `scripts/freeze_candidate.sh` now refuses a dirty tree, runs the
  gates, rebuilds the package and then prints the identity, with the whole run
  written to `build/package/candidate.txt`. `--full` adds the slow engine suite.
- Evidence: the script's dirty-tree refusal on its first run and the clean run
  that produced the log; `docs/DEVICE-HANDOFF.md` documents both forms.
- Verdict: the freeze has one entry point. Device acceptance remains outside it
  by design.

## 2026-10-29T04:00:00Z — the freeze log survives the package step

- Goal: G13. Requirement: R30 in progress.
- Observed: the first freeze run's log lost the gate output: it lived under
  `build/package`, which `package_device_app.sh` empties before packaging.
- Observed: the log now lives at `build/candidate.txt`. A `--full` run on the
  clean tree recorded the quick gates, then `engine verification: PASS`, the
  package check, the donor and patch identity and the package hash.
- Evidence: `build/candidate.txt` (6687 lines, commit 3e17474) and
  `docs/DEVICE-HANDOFF.md`.
- Verdict: the freeze produces one complete, readable evidence file. Packaging
  rewrites the zip each run, so the docs now say to read the hash from the log.

## 2026-10-29T04:20:00Z — the handoff preflight is clean

- Goal: G13. Requirement: R30 in progress.
- Observed: `scripts/device_handoff.sh` with no arguments builds the unsigned
  device shell, reports "Connected devices: 0", and skips installation with the
  exact command to use once a team and device are present.
- Evidence: the script's output on this machine; no hardware was attached and
  none is claimed.
- Verdict: the handoff gate behaves as documented. Every remaining item -
  physical acceptance, the campaign and multiplayer runs, performance,
  interrupted saves and the final freeze - needs that hardware.

## 2026-10-28T00:55:00Z — the simulator runs the game

- Goal: G04. Requirement: R06 and R15 in progress.
- Hypothesis: the simulator can run the real SDL/Metal path if the shell owns
  SDL's main-thread flag and the engine sees complete sandbox paths.
- Observed: the installed app had a dangling saves link from an old container,
  so startup stopped before the engine. The link now self-heals only when its
  target is gone; a link to another live saves directory is still refused.
- Observed: iPhone containers exceeded the settings disc-path buffer and the
  POSIX host-path buffer. A 241-byte discarded path and a 260-byte resolved file
  path were the two failures. `patches/0018-ios-long-paths.patch` raises those
  limits; `scripts/verify_patches.sh` now reproduces 55 files.
- Observed: SDL 3.4.18 refuses the simulator's Metal device because its family
  query describes the host GPU. `patches/sdl3-ios-simulator-metal.patch` relaxes
  that check only under `TARGET_OS_SIMULATOR`; the device lane is unchanged.
- Evidence: on iPhone 17 Pro / iOS 26.5, all eleven `filesys` archives opened,
  the action title rendered, Start handed off `d:\driving.xbe`, the Paris
  tutorial spawned, and the touch overlay drove the title into that handoff.
  Captures are `evidence/ios-shell/simulator-title.png` and
  `evidence/ios-shell/simulator-gameplay.png`.
- Observed: the committed build then continued through Select Codename,
  Operative difficulty and the single-player mission list, loaded The Exchange,
  and entered first-person gameplay. Holding the left touch stick moved Bond
  and holding the right stick turned the camera. Evidence
  `evidence/ios-shell/simulator-final-codename.png` and
  `evidence/ios-shell/simulator-exchange-gameplay.png`.
- Verdict: simulator action gameplay and the action-to-driving transition pass.
  The earlier "several minutes" note came from the game's internal timestamps,
  not wall-clock time; startup and mission-load timing remain to be measured.
  Physical acceptance, performance and feel remain separate work.

## 2026-10-28T01:40:00Z — Stop Game no longer strands a live mission

- Goal: G05. Requirement: R15 in progress.
- Observed: Stop Game in The Exchange hit the shell's 30-second timeout. A
  process sample later showed no game thread, and the backend reported one
  frame lasting 30,022 ms.
- Cause: the shell invalidated its SDL timer before joining. The game thread
  then waited for a main-thread present callback that had no event pump until
  its own 30-second timeout expired.
- Observed: the shell now keeps polling SDL while an engine is tearing down or
  switching. The Game thread's join rechecks its exit code after a timed wait.
  On the simulator, Stop returned to the shell immediately; the log shows
  `action stop observed`, `action cleanup complete`, and `action join complete`
  with no long frame.
- Evidence: simulator console log and `patches/0019-action-stop-observability.patch`.
- Verdict: Start, live gameplay, pause/resume and Stop pass on the simulator.
  The action-to-driving switch uses the same pumping rule and remains covered by
  the host transition suite; device behavior still belongs to G03.

## 2026-10-28T01:55:00Z — a second Start survives the new session

- Goal: G05. Requirement: R15 in progress.
- Observed: after a clean Stop, the next Start crashed at the first sky draw.
  The crash report showed `D3D9_DrawIndexedVertices` called with a null index
  pointer, from `View_DrawSky`.
- Cause: the action seam kept its bound-index pointer and cache handles across
  sessions even though the game heap underneath them had been replaced.
- Observed: graphics init now clears the bound-index pointer and both binding
  cache keys. The SDL GPU draw path reports a missing index buffer instead of
  dereferencing it. On the simulator, Stop then Start reached the title in the
  same process with no crash and no missing-index log.
- Evidence: the second-session title capture and `patches/0020-action-session-index-reset.patch`.
- Verdict: one Stop/Start cycle passes after live gameplay. Longer repeated
  sessions, driving handoff and physical-device stability remain.

## 2026-10-28T02:10:00Z — repeated starts clear their GPU session

- Goal: G05. Requirement: R15 in progress.
- Observed: the second session rendered, but a third session could stall with
  the engine waiting in `SDL_RunOnMainThread` while the main thread pumped SDL
  present callbacks. The action runtime had never reset the backend's recorded
  commands and per-session GPU resources between starts.
- Observed: the action runtime now calls the backend's session-cache reset before
  each start. `scripts/test_action_lifecycle.sh` passes three host cycles, and
  the simulator completed Stop, Start, Stop, Start with the third title visible.
- Open issue: pressing Start on the third title can remain on a black front end.
  The touch overlay is still present and the process continues rendering, so this
  is now recorded as a repeated-session input/front-end issue rather than a crash.
- Evidence: second/third-session simulator logs and
  `patches/0021-action-gpu-session-reset.patch`.
- Verdict: repeated starts render and the previous hard crash is fixed. Repeated
  front-end navigation is partial and remains active work.

## 2026-10-28T02:35:00Z — the black restart starts from a non-title page

- Goal: G05. Requirement: R15 in progress.
- Observed: Stop/Start from the title is stable. Stopping while the codename
  page is displayed reliably leaves the next session on a black game surface
  before the title, with the touch overlay still present.
- Hypothesis tested: stale save-flow or menu-manager state. Resetting `ls`,
  `ls_updating`, `enum_state`, the save dialog, and deleting all menu managers
  before cleanup did not change the failure. Those probes were reverted.
- Evidence: before/after page-transition logs and the simulator reproduction;
  the final tree contains no diagnostic prints or speculative reset code.
- Verdict: the trigger is narrowed to stopping from a non-title front-end page.
  The next investigation should target boot state after a non-title stop rather
  than the save-flow bookkeeping.

## 2026-10-28T03:20:00Z — Paris Prelude reaches the driving engine

- Goal: G04. Requirement: R06/R15 in progress.
- Observed: from a fresh simulator session, selecting Paris Prelude requested
  `d:\driving.xbe`, stopped and joined the action engine, started the driving
  engine from the 3,072-byte launch page, and entered the mission's sniper view.
  The running driving session reported 60 fps.
- Observed: Stop from the driving mission did not join within 60 seconds. A
  process sample puts the game thread in `Bond_CleanUp` -> `AStream::Destruct`
  -> `STREAM_destroy`, yielding while a sound stream is torn down. This differs
  from the action-engine SDL-present stop defect fixed earlier.
- Evidence: `evidence/ios-shell/simulator-paris-driving.png` and the filtered
  launch/join console log.
- Verdict: the action-to-driving handoff and driving gameplay pass on the
  simulator. Driving Stop is a separate open lifecycle issue.

## 2026-10-28T03:40:00Z — a new app Start ignores the previous handoff page

- Goal: G05. Requirement: R11/R15 in progress.
- Observed: after leaving a driving session, relaunching and pressing Start
  reopened the previous driving launch page and landed on Results instead of the
  title.
- Observed: `NightPadEngineHost` now deletes `LaunchState/psiLaunch.bin` for a
  user-initiated action start. In-process action/driving handoffs use a separate
  path that preserves the page the other engine just wrote.
- Evidence: the relaunched simulator reached Press START instead of Results, and
  the subsequent profile resume reached the saved Paris mission.
- Verdict: fresh app starts no longer inherit a stale cross-engine handoff page.
  Driving Stop remains the next lifecycle issue.

## 2026-10-28T05:00:00Z — the driving Stop hang is a 260-character path, and the black session is a load stall

- Goal: G05/G04. Requirement: R06/R11/R15.
- Observed: the driving session's Stop did not join; a sample put the game
  thread in `Bond_CleanUp` -> `AStream::Destruct` -> `SNDSTRM_destroy` ->
  `STREAM_destroy` yielding on `s->state == 1`. Live inspection (lldb) showed
  the stream's file slot at 0, its current request cancelled, and its last
  FILESYS operation already completed and returned to the free list, while the
  file worker was idle: the stream was waiting for a completion that could not
  arrive.
- Root cause: an action/driving stream opens `driving/mis01en.spe` and then its
  members as `|`-relative big-file entries. `Xbox_CreateFileA` resolved host
  paths into a 260-byte buffer, and the imported data's host path for the speech
  file is exactly 260 characters, so the `.spe` big file never opened. The
  speech event (`for_heli`) then queued requests against a stream whose open had
  failed; `FUN_0014aee0` left `state` at 1 for a read that was never issued,
  and cleanup waited on it forever.
- Fixed: the driving engine's `CreateFileA`/`DeleteFileA` use the host's
  `HOST_MAX_PATH` (4096 off Windows) instead of the Xbox's 260 (patch 0018).
  On the simulator `|for_heli.asf` now opens from `mis01en.spe` and reads flow.
- Hardened: a failed stream open finishes its request and lets the stream go
  idle; `STREAM_destroy` stops waiting when the file system no longer knows the
  operation (patch 0022). Host gates `test_driving_early_stop`,
  `test_driving_pause`, `test_engine_handoff` and the action lifecycle pass.
- Observed on the final simulator build: Paris driving view renders; Stop Game
  from the driving session returns to the shell home in 1.7-3.7 seconds
  (previously the 60-second timeout fired).
- Separately, a second engine boot in one app process can sit in
  `GAMEFLOW_LOAD_LEVEL` and show a black surface with the touch overlay; the
  engine advances ~60 frames/s and the state does not progress. A fresh app
  launch always reaches the title, and the front end's attract trailer
  (`073a0048.xmv`) is absent from the supplied 30 fps bundle, which shows as a
  black attract page that A skips. Movie open failures now count as finished
  (patch 0023) and the front-end idle counter starts at zero each session
  (patch 0024); the load-stall itself remains open.
- Evidence: lldb stream/op inspection, `/tmp/np-final.txt` console log, final
  simulator Stop timings, `scripts/verify_patches.sh` PASS (61 files),
  `scripts/verify_quick.sh` PASS.

## 2026-10-28T05:40:00Z — a second boot now starts at GAMEFLOW_BOOT again

- Goal: G05. Requirement: R11/R15.
- Observed: with the path and stream fixes in, a second Start in one app process
  still showed a black game surface with the touch overlay, while the engine
  advanced ~60 frames/s. A temporary `ResetMap_Load` trace never ran in the
  second session, and a sample put the game thread in `GameFlow_Main` ->
  `Game_Draw`, not in a load.
- Root cause: `StackIndex` and `GameStateStack` are process statics that begin
  as `{GAMEFLOW_BOOT}`. The first session ends with `GAMEFLOW_GAME` on top;
  a second launch in the same process inherited that stack, skipped
  `GAMEFLOW_BOOT`, never ran `bootup_bootup` or the level load that creates the
  front-end menu, and drew an empty screen.
- Fixed: `GameFlow_ResetForBoot()` puts `GAMEFLOW_BOOT` back on the stack, and
  `Game_Main` calls it (with the front end's idle-count reset) at the start of
  every session (patch 0024).
- Observed on the simulator: three consecutive Start/Stop cycles each render the
  title; Stop returns in 1.8-1.9 s; pressing START from the third title still
  hands off to `d:\driving.xbe` and renders the Paris mission; Stop from that
  session returns in 1.7 s.
- Evidence: simulator screenshots of sessions 2 and 3 at Press START,
  `/tmp/np-bootfix.txt`, and the `[load]` trace run that showed the missing
  `ResetMap_Load` call. Host gates still pass: action lifecycle (3 cycles) and
  `scripts/test_engine_handoff.sh`; `scripts/verify_patches.sh` PASS (62 files).

## 2026-10-28T06:20:00Z — handoffs open their window below the shell, and the Paris tutorial is playable

- Goal: G05/G06. Requirement: R06/R15.
- Observed: after a handoff, the driving engine reported 335 draws at 57 fps
  while the screen stayed black. The new SDL window's root view controller had
  `view == nil`: it never presented, so no Metal view existed and the GPU
  presented off-screen. Six `Unbalanced calls to begin/end appearance
  transitions` warnings appeared, one per window creation.
- Cause: `switchEngine` created the target engine's window while the shell
  window was still at `UIWindowLevelNormal + 2` (gameplay). The plain Start path
  creates its window at the normal level, which is why restarts worked.
- Fixed: `switchEngine` drops the shell window to the normal level before
  closing the old engine window and starting the target; `updateGameplaySurface`
  raises it again afterwards. Handoffs now render on the first try.
- Observed on the simulator: from Press START the action engine handed off,
  the Paris intro rendered, the sniper tutorial appeared, the right trigger
  fired and the game showed Mission Failed, and REPLAY TUTORIAL reloaded the
  mission; Stop returned to the shell in 1.7 s. A fresh app launch still shows
  the title and repeated Start/Stop cycles still reach it.
- Evidence: simulator screenshots of the handoff, the sniper tutorial and the
  Mission Failed screen; `/tmp/np-handoff2.txt`.

## 2026-10-28T06:45:00Z — sound banks are freed at session end, not in the next session

- Goal: G05. Requirement: R11/R15.
- Observed: after reaching the Paris mission and pressing Stop, the next Start
  crashed with SIGSEGV. The crash report's faulting thread: `Mem_Free` <-
  `psiSFXFreeFileMem` <- `SFXReset` <- `Sound_Kill` <- `ResetMap_Load` <-
  `mainloop`; no crash report appeared for the repaired run.
- Cause: the action engine's sound banks are process statics and hold sample
  memory in the game heap. `cleanupSystem` called only `SoundShutdown`, which
  unbinds the voices but leaves the banks loaded, so the next session's level
  load called `Sound_Kill` -> `SFXReset` and freed pointers into the previous
  session's heap.
- Fixed: `SFXShutdown` unloads the banks and stops and frees the sound stream at
  session cleanup, after `SoundShutdown` has unbound the voices and while the
  heap is still valid (patch 0025).
- Observed on the simulator: Start -> Paris intro/mission -> Stop (4.4 s) ->
  Start again reaches Press START with the process alive and no new crash
  report. `scripts/verify_patches.sh` PASS (65 files).

## 2026-10-28T07:30:00Z — first handoff renders; a repeated handoff still recreates a dead window

- Goal: G05/G06. Requirement: R06/R15.
- Observed: after the sound-bank fix, a first action-to-driving handoff renders
  Paris and the sniper tutorial; the right trigger fires; Stop returns in 1.7 s.
  A second handoff in the same process (Start, handoff, Stop, Start, handoff) can
  create an SDL window whose root view is `SDL_uikitview` instead of the Metal
  view, while the engine reports ~360 draws at 60 fps and the screen stays black.
- Tried, each without fixing the repeated case: dropping the shell window to the
  normal level while the target window opens (this fixed the earlier always-black
  handoff), one extra main-runloop turn before starting the target, keeping SDL
  initialized instead of `SDL_Quit` (the device then outlives nothing but the
  window still fails), and reusing the window (SDL rejects a second window per
  display with "Only one window allowed per display").
- Kept: the shell window-level drop and the one-turn delay, because the first
  handoff now renders reliably across fresh launches; the repeated-handoff
  window creation is recorded as an open simulator issue with the fresh-launch
  workaround.
- Also observed: the simulator's audio mixer produces sound (about 11k chunks
  mixed with about 3.7k carrying sound during the front end), and the existing
  `Saves/slot1.sav` is a 25-byte `nightpad-save-sentinel-01` fixture, so a real
  in-game save is still not produced by the front end path.
- Evidence: simulator screenshots of the handoff and black repeated handoff;
  `/tmp/np-final2.txt`, `/tmp/np-noquit.txt`; `scripts/verify_patches.sh` PASS
  (65 files).

## 2026-10-28T08:30:00Z — touch controls and the three-dot menu take SunPad's layout and style

- Goal: G06. Requirement: R14/R15.
- Observed: the previous overlay was a scatter of coloured rounded rectangles:
  tall triggers at the top corners, White on the left, Black on the right, and
  Start/Back in the middle top; the sticks were rounded squares. The user asked
  for SunPad's layout and interface as the starting point.
- Studied `references/sunpad/apple/ios/SunPadGameOverlay.mm`: round translucent
  sticks in the lower corners, a face-button diamond on the right with a large A,
  wide shoulders at the top corners, Start/Back at the top left, a D-pad beside
  the move stick, and a 40-point capsule ellipsis menu using a plain button
  configuration over a dark translucent plate.
- Changed: the phone and tablet defaults now follow that arrangement (large A,
  medium B, small X/Y; White/Black down the right edge; Start/Back capsules;
  round sticks). Round controls are forced square about their centre so they
  stay circular at any canvas aspect. Sticks and shoulders use SunPad's neutral
  translucent fills with 2-point white borders; face buttons keep a subtle Xbox
  colour tint. The menu button uses SunPad's capsule configuration and 12-point
  top/trailing inset. The layout file version moved to 2 so old saved layouts
  fall back to the new defaults without an error alert.
- Verified on the simulator with `--preview-gameplay --show-touch-controls`:
  the overlay renders as a controller, the touch START enters the Paris mission,
  the look-stick drag registers, and the three-dot menu opens over gameplay.
  `scripts/test_touch_layout.sh` PASS (including the no-overlap check at
  844x340, 800x320 and 1024x700 with the 44-point floor) and
  `scripts/verify_quick.sh` PASS.

## 2026-10-28T09:00:00Z — overlay legibility and the tablet layout

- Goal: G06. Requirement: R14.
- Changed: each control gets a soft dark shadow (35% black, 3-point radius) so
  the white borders stay readable over bright scenes; the translucent fill is
  unchanged.
- Verified: the overlay renders over the title and the Paris mission on the
  iPhone 17 Pro, and after shutting the phone down and booting the iPad Pro
  13-inch (M5) in landscape, the tablet defaults render the same arrangement
  with round sticks, the face diamond and the capsule Start/Back.
- One simulator was used at a time; the iPad was shut down before the phone was
  booted again.

## 2026-10-28T09:40:00Z — the three-dot menu reads as one clean list

- Goal: G06. Requirement: R14.
- Changed: the top-level menu is now Game / Controls / Display / Assists / Data /
  Info, each on one line. "Game Data & Saves" became "Data" with a "Manage Game
  Data…" entry (the old title wrapped to two lines). The always-disabled
  "No controller connected" row now appears only when a controller is connected,
  and the disabled assist note is gone.
- Verified: the menu and the Data submenu render cleanly over the shell and over
  gameplay, and the accessibility tree lists the shortened titles.

## 2026-10-28T08:05:00Z — the controls are GalaxyPad's, ported rather than re-invented

- Goal: G06. Requirement: R14.
- Observed: the SunPad-derived arrangement still read as a custom layout. The
  user asked for GalaxyPad's controls to be inherited and refined.
- Changed: the phone defaults now come from
  `references/galaxypad/apple/ios/GalaxyPadGameOverlay.mm`: move stick lower-left
  with the D-pad above it, camera stick lower-right, A large in the corner with
  B up-left, the light X/Y pair beside them, a grey START inward at the upper
  right, and GalaxyPad's auxiliary row along the bottom holding White, Black and
  Back. The D-pad is four separate round keys in GalaxyPad's 3x3 hit group, not
  one grey plate. Buttons use GalaxyPad's palette and metrics: A green, B red,
  X/Y light grey with dark lettering, purple triggers and grey aux keys,
  18-point bold titles, two-point white borders at 0.36 alpha, no shadow. The
  move stick uses GalaxyPad's dark base and grey thumb; the look stick uses its
  amber tilt-stick treatment.
  White/Black/Back use WHT/BLK/BACK at 10 points to fit their 44-point keys.
- Bumped the layout version to 3 so saved layouts fall back to these defaults.
- Verified on the simulator: the overlay renders over the title with the touch
  START entering the game, and `scripts/test_touch_layout.sh` passes with no
  overlaps for phone defaults at 844x340, 800x320 and 1024x700, and tablet
  defaults at 1024x700 and 1366x1032.

## 2026-10-28T08:20:00Z — repeated sessions release their SDL GPU window; GalaxyPad UI tightened

- Goal: G05/G06. Requirement: R06/R14/R15.
- Observed: the second action-to-driving handoff could recreate a window whose
  UIKit view never acquired a Metal layer, even while the engine presented into
  the retained SDL GPU device. The window was destroyed while the device still
  held its per-window claim.
- Fixed: `D3D9_ReleaseGpuWindow` now calls `SDL_ReleaseWindowFromGPUDevice` and
  `HostWindow_Close` invokes it before `SDL_DestroyWindow` (patch 0026). Stop
  Game followed by Start Game renders Press START again in the same process;
  the former second-session black surface is gone. The full Stop -> Start ->
  driving-handoff route still needs a repeat before it replaces the older
  driving-round-trip evidence.
- UI refinement: control opacity now reaches the live overlay instead of only
  the editor. Tablet controls use GalaxyPad's fixed iPad point sizes, with the
  action cluster and right stick separated so they do not overlap on a 1024
  point landscape canvas. The three-dot button is 44 points. Start/Stop is a root
  action; the remaining groups are Display, Controls, Data & Saves,
  Enhancements and Help & Feedback, with App Pause under Controls. The full set
  fits without scrolling on the iPhone 17 Pro simulator.
- Verified: the title and touch START render after Stop and Start; the D-pad,
  sticks, face cluster and auxiliary row are visible over live gameplay; the
  iPad Pro 13-inch landscape uses the fixed point layout;
  `scripts/test_touch_layout.sh` and `scripts/test_contrast.sh` pass. Evidence:
  `evidence/ios-shell/galaxypad-controls.png`,
  `evidence/ios-shell/galaxypad-menu.png` and
  `evidence/ios-shell/galaxypad-controls-ipad.png`.

## 2026-10-28T08:50:00Z — the second driving handoff creates its own device and window

- Goal: G04/G05. Requirement: R06/R15.
- Observed: the repeated-handoff black surface persisted after releasing the SDL
  GPU window. Console logging showed the second `DRIVING.XBE` session reached
  `main` and rendered shaders but never logged `Direct3D_CreateDevice`, never
  claimed a window and never made a Metal view. UIKit listed a new
  `SDL_uikitviewcontroller` rooted in the generic `SDL_uikitview` layer.
- Root cause: the driving engine keeps its device in the process-global
  `D3DDevicePointer`. The first driving session left it non-null; the second
  session took EAGL's existing-device branch, called the no-op Reset/Persist
  paths, and rendered into the retained offscreen back buffer without a new
  swapchain.
- Fixed: `D3dSeam_ResetDeviceForSession()` clears the driving device token
  before each driving session, so `SetupFrameBuffers` calls
  `Direct3D_CreateDevice` and claims the new window. Patch 0026 now contains
  both this reset and the prior-window release before destruction.
- Verified in one process: action title -> driving Paris intro -> Stop -> action
  title -> driving Paris intro again -> sniper gameplay -> Mission Failed. The
  console showed a new D3D device, a successful window claim and device-ready
  log for both driving sessions; the second frame is captured in
  `evidence/ios-shell/repeated-driving-handoff.png`.
- Evidence: `/tmp/np-handoff-window2.log`; `scripts/verify_patches.sh` PASS
  (70 files reproduced from `8779cf79ff623b83b53b9acf9c0b0cd6639b75ab`).

## 2026-10-28T11:55:00Z — the Xbox finish lands and repeated sessions reuse their stacks

- Goal: G04/G06. Requirements: R07, R12, R29.
- Recovered: the working tree held an uncommitted touch-overlay treatment and
  an untracked `0027-thread-stack-reuse.patch`. The patch covered engine
  threads but not the in-window stacks created for host timers, so the tracked
  series no longer reproduced the vendor tree.
- Controls: GalaxyPad's geometry now carries an Xbox finish rather than its
  purple and amber palette. Sticks and shoulders are graphite with a recessed
  well and a highlighted thumb; the D-pad is one dished cross driven by two
  arms; keys have a restrained top-light gradient; A, B, X and Y use the four
  Xbox colours with dark lettering; White, Black and Back use icons or dark
  lettering on light keys. Start and Back draw their system symbols. The
  editor uses the same dark-label rule, and the layout remains GalaxyPad's.
- Stacks: patch 0027 now returns both pthread and timer stacks to a mutex-held
  process cache when their owner is released, and takes the first matching
  block for the next thread. The cached block stays in the game window, so a
  repeated engine launch reuses the same valid addresses instead of reserving
  another 1 MB stack per thread.
- Verified: `scripts/test_contrast.sh` and `scripts/test_touch_layout.sh` pass;
  the simulator shell builds; the live overlay and the iPad landscape frame
  render with the new finish. Fifteen action cycles all join with resident
  memory steady at 264 MB, ten driving cycles settle at 280 MB, and
  `scripts/test_engine_roundtrip.sh` passes action -> driving -> action.
  `scripts/verify_patches.sh` reproduces 70 files from the pinned revision.
- Evidence: `evidence/ios-shell/xbox-controls.png`,
  `xbox-controls-live.png`, `xbox-controls-ipad.png`; `patches/0027-thread-stack-reuse.patch`;
  `/tmp/np-quick-current.log`.
- Next: produce a real in-game save and continue the first-play campaign route
  on the simulator; physical acceptance still needs a signing identity and a
  connected iPhone and iPad.

## 2026-10-28T12:00:00Z — a real codename profile survives relaunch

- Goal: G05. Requirement: R11.
- Observed: the simulator's Saves directory held `BOND.dat`, a 166-byte file
  with the engine's `PLRS` record stream rather than the 25-byte fixture. It
  was written by the game at 04:15 and had not changed since.
- Verified after terminating and relaunching the app: the fresh engine session
  listed BOND under Select Codename, its mission list still opened on The
  Exchange, and selecting it loaded that mission into gameplay. The file stayed
  byte-identical through the session and a clean Stop Game.
- Evidence: `evidence/ios-shell/codename-profile-persisted.png`,
  `bond-profile-progress.png` and `the-exchange-loaded.png`.
- Verdict: the profile and campaign-progress path is real, not a fixture. An
  auto-save written after an objective, an interrupted engine write and the
  signed app-update path remain under R11.
- Next: take a checkpoint through an objective, then compare the file and
  resume from it; continue the campaign route while the device remains
  unavailable.


## 2026-10-28T16:32:14Z — restore the loop and protect profile writes

- Goal: G05. Requirement: R11. Hypothesis: the POSIX `fopen(..., "wb")`
  truncates the previous profile before its new bytes are safe; staging and
  atomic replacement should preserve complete old/new bytes on interruption.
- Recovery: continued from `5aa9531` on `codex/resume-save-durability`.
  Recreated the active app goal; the implementation state now names G05.
  Shut down the stale NightPad iPad preview, keeping only the iPhone simulator.
  Rechecked signing and hardware: zero identities and no physical devices.
- Change: patch 0028 writes and flushes a unique hidden stage, retains a
  flushed previous copy as `.dat.bak`, and atomically replaces the live file.
  Backups stay out of the Codename list, hidden stages stay out of exports,
  and explicit codename deletion removes the backup. Serialized bytes and the
  game's save triggers are unchanged. See decision 0015.
- Expected/observed: all 12 injected I/O cases and SIGKILL before and after
  commit retain a complete old/new file and the appropriate previous copy.
  Actual `psiSaveData`, `psiLoadData`, poll and delete entries pass. The native
  engine, both iOS lanes, quick verification and three native lifecycle cycles
  pass. Patch verification reproduces 72 files from the pinned engine.
- Original UI: made a separate NPQA copy of the valid profile, changed Classic
  Bond to NightFire in Controller Setup, then used Save Codename. Exactly
  byte 8 changed in the 166-byte file, the previous copy matched exactly, and
  NightFire reloaded after terminating and relaunching the app. Existing saves
  stayed byte-identical through updates and testing.
- Evidence correction: decoding the prior BOND.dat shows mission mask `0x3`
  and twelve zero scores/Bond-moment counts. The 12:00 entry proves a real
  initial profile and mission load, not earned campaign progression. Source
  confirms that mission results write progress; individual objectives do not.
- Evidence: `evidence/save-durability/` (private snapshots, decode, UI result
  and captures); `build/tests/engine-save/` (focused result, native build,
  lifecycle and quick verification logs). Dependency lock SHA-256:
  `f2ae8ce569ba6fe8676fdfcdc4bd4a4c9a490aa483d1d661afed2dd63742b08e`.
- Limitations: host syscall faults and process interruption do not prove
  physical power-loss behavior. A completed mission's results save, picker
  selection and signed-device update/acceptance remain open. No goal is waived.
- Next: finish the original mission-toggle relaunch check on NPQA, then
  continue a fresh campaign route through a real mission-results save.

## 2026-10-28T16:40:01Z — original unlock persistence and final package

- Goals: G05/G09. Requirements: R11/R19/R26. Expected: an original mission
  toggle persists through save/relaunch and reverses from the loaded state;
  an invalid entry changes nothing. Use only NPQA, preserving existing saves.
- Observed: touch keyboard entry showed Unlock successful. Save Codename
  changed the mission mask `0x3 -> 0x103`; an in-place final-build update and
  app relaunch/load retained it. The same code then saved `0x3` again, with
  the entire file byte-identical to its pre-unlock state. Each backup matched
  the preceding file. An invalid entry showed no success; saving afterwards
  left the profile byte-identical. All original profiles remained unchanged.
- Final build: simulator and device lanes pass quick verification; the native
  action targets build. The unsigned Release device IPA rebuilt at 3.6 MB and
  passed arm64, system-only linkage, landscape and file-sharing checks.
- Evidence: `evidence/save-durability/unlock-result.json`, `unlock-success.png`,
  `build-identity.json`; `build/tests/engine-save/package-device.log`.
- Verdict: simulator mission-toggle persistence/reversal and invalid input pass.
  Other unlock families and physical acceptance remain. No campaign progression
  credit: the underlying profile still has only the two initially open missions.
- Resume: only the iPhone simulator is booted. NPQA is saved with NightFire
  controls, initial mission mask `0x3`, zero scores and no app assists. The next
  required campaign experiment is a fresh codename through the Paris mission,
  continue past its results, then relaunch and decode/load earned progress.
  Keep originals and the private before-update snapshot. Use the existing
  simulator app; rebuild only if code/input identities change.

- Checkpoint detail: the prior app settings had immortality enabled. Disabled it
  through Enhancements and verified both assist settings persisted as `0` before
  the next campaign attempt. Unlock/settings tests above are UI/persistence
  evidence, not unassisted campaign evidence. Stop Game joined cleanly; the
  single booted iPhone simulator is now at the shell with its data ready.

## 2026-10-28T17:36:21Z — fresh campaign evidence, two bot matches and real display settings

- Goals: G05/G07/G08/G09. Requirements: R09/R11/R17/R18. Continued from
  `1afa631`; only the existing iPhone simulator was booted; both app assists
  were off. No prior acceptance gate was waived.
- Fresh profile: created NPRUN through the original keyboard and Save flow,
  decoded initial mask `0x3` and twelve zero scores, then selected NightFire
  controls. Operative Paris showed its intro and real action-to-driving
  handoff. Touch fire reduced ammunition; failure, Replay and Quit back to
  the action title worked. Timed aiming attempts did not complete the mission.
  NPRUN and every pre-existing profile stayed byte-identical; no campaign
  completion or earned-progress credit is claimed.
- Multiplayer: the original front end enabled all six bot slots for a
  one-minute Arena match on Skyrail, one human using NPRUN, Normal weapons,
  ten points and friendly fire off. Two runs reached debriefing, with the
  second started by Replay in the same app process. Winners had four and
  three victories; the second results recorded two human deaths. The engine
  log lists all six bot skins (6-11). Other modes/maps and physical ports remain.
- Hypothesis: `Widescreen=on/off` is a shell/engine contract mismatch because
  the action parser uses `atoi` and the driving seam uses `strtol`. Added an
  actual action-parser test: 4:3 passed but 16:9 failed before the fix.
  Writing numeric `1/0` makes both pass; FOV/FPS/disc-root checks also pass.
- Lifetime: the action settings cache survives app-local engine restarts.
  Patch 0029 clears/reloads it before each session, while the old thread is
  stopped. Tests rewrite and reload aspect, FOV and disc root in one process.
  On the final simulator build, one PID logs `widescreen=1 fov=70`, then
  `widescreen=0 fov=70` after Stop/native aspect change/Start. The launch files
  match; Original 4:3 and both assists off are the restored baseline.
- Verification: real parser tests, quick verification, both iOS lanes, native
  action targets and three joined native action cycles pass. Final simulator
  and unsigned Release device builds/package checks pass. Patch provenance
  reproduces 73 files from `8779cf79` with 29 patches.
- New verified boundary: R18 still fails presentation. The SDL GPU blit uses
  the whole swapchain, stretching the frame on a phone. Do not count the menu,
  numeric-key or cache fixes as proof of correct display proportions. The
  six-bot logs also report the 128-buffer tracking limit; audible impact is
  unverified, not assumed safe or broken.
- Evidence: `evidence/campaign-first-play/nprun/`,
  `evidence/multiplayer/arena-skyrail/`, `evidence/display-settings/`,
  `build/tests/engine-settings/`; decision 0016. Full artifact hashes and
  source-file hashes are in the private display build identity.
- Next: implement aspect-fit presentation with cleared bars, preserve the
  controls' usable canvas, and verify action/driving plus phone/tablet.
  Then return to mission completion/results saves and the multiplayer matrix.

- Resume checkpoint: the final simulator app is installed and stopped at the
  data-ready shell, with Original 4:3, FOV 70 and both assists off. Only the
  iPhone simulator is booted. The app was launched with `--log-input` and its
  stdout/stderr go to `evidence/display-settings/session-*.log`. The untouched
  fresh NPRUN profile and before/after snapshots remain available. Start with
  decision 0016 and `sdlGpuBackend.cpp:PresentOnWindowThread`; preserve the
  offscreen back buffer and rendering goldens while fixing only presentation.

## 2026-10-28: fit presentation, encode driving widescreen, preserve replay timing

- Previous goal turn: progress. Continued from clean commit `56236fc` with
  the active goal intact. No goal completion or blocker threshold is claimed.
- Hypothesis: the whole-swapchain blit causes stretched phone output. Patch
  0030 fits the selected aspect in the current window safe area, rounds its
  logical coordinates inward to drawable pixels, centers and clears bars.
  Render targets, readbacks and offscreen rendering are unchanged. Geometry
  tests cover both aspects, safe areas, rotation/resize shapes, odd/zero and
  large sizes. SDL's pinned Metal implementation clears the attachment before
  applying the blit viewport, verified from its source.
- Simulator evidence: phone action titles in 4:3/16:9 and a 16:9 driving HUD;
  tablet action titles in both aspects and a 4:3 driving HUD. Touch controls
  remain usable on their saved safe-area canvas. Only one simulator was
  booted at a time. The tablet received prepared local data through the app's
  validated Import from NightPad Folder flow.
- The tablet scope found a second contract defect: driving XC_VIDEO returned
  bit 0, while its actual XAPI getter reads bits 16..22. Patch 0031 returns
  0x10000 for widescreen. The expanded settings test links the real kernel,
  XAPI and POSIX profile reader along with the action parser. It fails before
  the change and passes both modes/reloads afterward. The rebuilt tablet
  scope changes from an oval to a circle in 16:9. Broader scope/FOV/cinematic
  combinations and physical display/performance remain unverified.
- Regression: CastleIndoors1 stopped at frame 2, including with the old
  presentation backend rebuilt. Patch 0023's generic missing-movie completion
  changed its recorded input timing. Patch 0032 removes that generic behavior
  and retains the dedicated missing-attract-page recovery. The unchanged
  recording then matches all 635 frames. No recording, checksum, assertion or
  golden was changed. A fresh full pass over the eleven complete recordings
  is live; do not claim its historical 11/12 result as a new post-fix pass.
- Verification completed: final quick gate, simulator/Debug device and Release
  device builds, unsigned package check, 32-patch reconstruction of 75 files,
  three final native action cycles and one driving cycle. Logs and private
  captures are in `build/tests/presentation/` and `evidence/presentation-fit/`.
  Final source/artifact hashes are in that evidence's build-identity JSON.
- Save protection: NPRUN is still byte-identical to its before-mission copy.
  No earned progression is credited. Both assists remain off. The tablet app
  is cleanly stopped at its shell with 16:9/FOV60/1x/FXAA; the phone is shut
  down and retains 16:9/FOV70 from the comparison. New container paths are in
  the private checkpoint files; reinstalling moved the earlier recorded path.
- Exact resume: poll exec session `57557` using `write_stdin`, then inspect
  `build/tests/presentation/replay-corpus.log` and its timestamped result JSON.
  The runner was confirmed live as PID 51735 with an action test child, and
  had passed the first four recordings. Never duplicate a live runner. Record
  the terminal corpus verdict, then resume earned NPRUN mission/results save
  and remaining campaign/multiplayer/display coverage. Shut down the tablet
  before booting the phone. SpaceStationD media and physical signing/hardware
  remain external; no core route has been waived. Decision 0017 explains the
  changes and limits.

## 2026-10-28: finish replay recheck and repair native menu ownership

- Previous goal turn: progress. Reused the confirmed live replay process from
  session 57557; it terminated successfully. All eleven complete recordings
  matched all 208,364 frames after patch 0032. SpaceStationD remains blocked by
  missing media. The native engine did not change during this turn; this is
  fresh regression evidence, not a replay of the old result.
- Fresh NPRUN selected The Exchange from its original initial unlock, on
  Operative with both assists off. Restored 640x480/4:3/FOV60/FXAA through the
  native menu. The briefing plays, and move/look/jump, fall damage, guard fire,
  death and Replay work. Smaller stick deflections can fall below the retail
  engine's wide deadzone. Larger deflections move and turn; the initial low
  wall requires jumping before moving onto the road. No input-curve change
  was made. Two failed runs still leave the profile exactly unchanged.
- The second attempt exposed a UI boundary defect: root UIMenu had no pause
  callback. Earlier tests only covered the engine pause boundary and modal
  panels; the blanket claim that the three-dot menu already paused was wrong.
  Added UIControl's documented menu visibility hooks following the pinned
  GalaxyPad donor, with dismissal reconciliation at animation start and menu
  rebuilding deferred while visible.
- Menu, surfaces/inline panels, alerts and application activity independently
  own the pause. WillResignActive/DidBecomeActive replace early foreground
  resumption. Starting/handoff reapplies the hold and binds controller input
  even under UI. The mixer now drops stale edges and requires neutral buttons,
  triggers and sticks per source before accepting input again. New host tests
  exercise ownership handoffs, inactive dismissal, alerts and source release.
- Live simulator evidence: action frame 927 settles and remains held through
  menu-to-layout-sheet transfer; Cancel releases it. Menu plus Home/return
  retains frame 3685. The driving simulation settles at 1277 while its menu is
  open. The final build holds App Pause and a nested menu at 1188 until Back to
  Game, then advances to 3383 before Stop. Both final quick gates and unsigned
  Release packaging pass; the 32 patches reproduce 75 vendor files.
- New required repair: driving `PlayMPC::Play` ignores lifecycle pause/stop in
  its blocking movie loop. The intro finishes under native hold at simulation
  frame zero, which is not a movie-pause pass. R15 is explicitly failed for
  this phase. Inspect `common/fmv/FmvAudio.h`, `FmvAudioSdl.cpp`, `FmvAudio.cpp`
  and the action/driving movie players. Add voice/clock pause with correct
  silent/drained/virtual-clock resume and stop while paused, then test an
  actual intro. Do not just wait for the simulation counter to advance.
- Evidence: `evidence/action-demos/20261028T180115Z/results.json`,
  `evidence/presentation-fit/replay-corpus-result.json`,
  `evidence/campaign-first-play/exchange/`, `evidence/native-ui-pause/`,
  `build/tests/native-ui/`; decision 0018. Source/binary/package hashes are
  in the private build identity. No personal save or retail capture is tracked.
- Exact resume: no replay/build job remains live. The latest simulator app is
  installed and cleanly stopped at the data-ready shell. Only the iPhone is
  booted. It retains Original 4:3, FOV60, 1x, FXAA, both assists off; NPRUN has
  no earned progress. Repair the blocking movie native pause next, then resume
  a real mission-results save/relaunch and the outstanding campaign, objective
  multiplayer, display and physical gates. Goal remains active, not blocked.

## 2026-10-28: pause real movies and stop before simulation starts

- Previous goal turn: progress. Patch 0033 adds movie voice/clock pause to both
  players and pause/stop polling to the blocking driving loop. Paused time is
  excluded for silent, queued, drained and virtual clocks; other voices on the
  shared SDL device keep running. Windows code mirrors this but is untested.
- Per-session starts clear old pause and frame counters. The shell's frame-zero
  Stop guard now accepts an active blocking movie and requests stop before
  releasing UI ownership. Movie counters report presented frames separately.
- Actual SDL audio tests pass. The real native driving intro freezes 3 -> 3,
  resumes, stops while paused within five seconds and joins, twice in process.
  Initial tests correctly failed on the default PAL fixture. The corrected,
  test-owned launch seed selects supplied NTSC media; no app save was changed.
- Simulator action movie clock holds 11.357621 -> 11.357622 seconds across a
  native menu. Paris holds at movie frame 77, resumes, then holds at 624 with
  simulation zero. Stop while paused returns to the shell in 1.825 seconds.
  The NPRUN profile remains exactly byte-identical to its before-mission copy.
- Native action pause, rebuilt native targets, both iOS lanes, quick gates,
  35-export link, 33-patch/80-file reproduction and unsigned Release package
  pass. A fresh unchanged CastleIndoors1 replay matches all 635 frames. The
  full eleven-recording evidence remains the patch-0032 run, not a new 0033 run.
- Newly observed: Stop/Start during an action movie opens a zero-score Results
  page instead of the title. No progress is credited. Investigate retained
  launch/front-end state next, then resume the earned campaign/results save.
- Evidence: `evidence/fmv-pause/`, `build/tests/fmv-pause/`, decision 0019,
  `evidence/action-demos/20261028T193202Z/results.json`. The one booted phone
  simulator is cleanly stopped at the data-ready shell. No build/replay job
  remains live. Goal stays active; physical signing/device and PAL media remain
  external dependencies, with useful independent work still available.

## 2026-10-28: reset interrupted action boot and handover state

- Previous goal turn: progress. An interrupted action movie left ResetMap_State
  at AFTER_MOVIE. Only resetting the flow stack let the next front end finish
  that phase and open a zero-score Results page. Patch 0034 resets the loader
  to START at boot. The source audit also found a per-process launch-page cache
  that retained the first boot's present/absent answer. Each new boot now clears
  that cache while keeping the page stable within a boot.
- Actual private engine regression failed before for all four interrupted load
  phases and four new/replaced handover cases; it passes after the fix. It
  covers initial absence, new/replaced/deleted pages, stable per-boot bytes and
  direct-level bypass. No extra app export or campaign-save fixture is added.
- Simulator Exchange movie Stop/Start reaches the original Press START title
  in one process. NPRUN Paris still plays and accepts input; a failed run's
  original Quit returns through a freshly read handover page to the mission
  menu. The profile remains byte-identical to the before-mission copy. No
  earned mission completion or results-save credit is claimed.
- Native action targets, mixed action -> driving -> action joins, the unchanged
  635-frame CastleIndoors1 replay, quick gates, both iOS lanes, 35-export link,
  34-patch/81-file reconstruction and rebuilt unsigned Release package pass.
  Signing/device preflight again finds zero identities and no hardware.
- Evidence: `evidence/action-boot/`, `build/tests/action-boot/`, decision 0020,
  `evidence/action-demos/20261028T194047Z/results.json`. No build/replay job is
  live. Only the phone simulator is booted, app cleanly stopped, baseline
  4:3/FOV60/1x/FXAA with both assists off. Continue real NPRUN earned mission /
  results save and relaunch, then remaining campaign/multiplayer/display
  coverage. The goal remains active; no blocker impasse is claimed.

## 2026-10-29: investigate the truck route and repeated-boot audio

- Previous goal turn: progress (f504a63 plus verified interrupted-boot and
  handover evidence). The live NPRUN Exchange route now passes the outer arch
  with much less damage by using the supply truck's cover. On-foot fighting
  reached the closed main gate; no objective or mission was completed. The
  profile remains byte-identical to its initial copy.
- A fresh unchanged CastleExterior recording matches all 5,649 frames and
  periodic native captures show the higher-ledge / truck-bed / crouch route
  through the main gate into CastleCourtyard. This is a route guide, not a
  continuous campaign pass. Restart through the original UI and try that path.
- Simulator control then reports a locked Mac and cannot interact. Unlock was
  requested once. The last native-menu trace holds frame 16005; the f504a63
  app/run remains installed and preserved. Do not reinstall or call its live
  run completed while access is unavailable. B03 tracks this external input.
- Independent full native engine verification passes at f504a63, including
  lifecycle, boot reset, both pause paths, actual intro pause/stop, early stop,
  transitions, handoff and mixed round trip. Logs:
  `build/tests/campaign-route/verify-engine.log`.
- Audited the repeated-session sound-buffer warning. Each action boot creates
  192 buffers, but a fixed 256-entry registry kept every earlier boot. New
  buffers were handed to the game without PCM ownership or per-frame 3D
  tracking. Patch 0035 releases previous source voices and buffer objects at
  the next device creation, then resets the registry and creation indices;
  the shared output/movie streams and ordinary level resets are preserved.
- Actual SDL/cache/mixer regression fails before: 2,624 registry warnings over
  fifteen boots, untracked later PCM and fifteen retained playing voices.
  Afterward all 2,880 buffers fit per-boot tracking, PCM ownership passes, only
  the current test voice remains, final reset leaves zero voices, no overflow.
  Windows mirrors the source fix but is not built/tested here.
- Fifteen real action cycles join with settled threads six/seven and no buffer
  overflow. RSS is 222 MB on the cold first cycle and 264 MB on the final one;
  this does not prove physical stability/performance. Focused unchanged
  CastleIndoors1 still matches all 635 frames. Quick gates, both iOS lanes,
  35-export link, 35-patch/83-file reconstruction and rebuilt unsigned Release
  package pass. The full post-0035 native suite terminates successfully:
  lifecycle, boot, both pause paths, assists, actual intro pause/stop, early
  stop, three transition cycles, handoff and mixed round trip. No test job
  remains live. Evidence is under
  `build/tests/action-audio-sessions/`, decision 0021.
- No earned campaign/results save, new simulator audio acceptance or hardware
  acceptance is credited. Resume the preserved route after Mac unlock, protect
  NPRUN, install the new build only when appropriate, and continue all original
  campaign/multiplayer/display/device gates. SDL HRTF/reverb remain unverified
  fidelity gaps. Goal stays active; independent work is making progress.

- Final checkpoint: the control tool again confirms Mac lock. Phone simulator
  still has f504a63 held at frame 16005; new patch-0035 artifacts are built but
  not installed. New source/build hashes are in the private audio-session
  identity. Resume after unlock without pretending this paused run is saved.


## 2026-10-29T01:51:24.302849+00:00 — unlocked simulator campaign resume

- User confirmed unlock; simulator input works. A task-owned four-hour display/idle sleep assertion is active at the user’s request. Authentication settings are unchanged.
- Protected NPRUN remains byte-identical, cleanly stopped the old attempt, installed source 241160e and verified its binary against the post-0035 build. Original UI NPRUN/Operative/Exchange is active at the high ledge. B03 resolved.
- Identity: `evidence/campaign-truck/resume-identity.json`. No completed mission or earned save is credited. Continue the supply-truck/crouch route through the main gate.


## 2026-10-29 03:22 UTC — live truck objective and complete unlock-family subset

- Hypothesis: the higher ledge/truck/crouch route reaches CastleCourtyard without assists. On installed source 241160e, original NPRUN/Operative completed the first objective and changed section automatically. Original Replay recovered from three courtyard gameplay deaths. Clean Stop; no completed mission/results save, and NPRUN stayed byte-identical. The next route clears the raised pavilion before entering the dolphin fountain guardroom. Gameplay deaths are not evidence of an engine regression. `evidence/campaign-truck/result.json`.
- Independent R19 hypothesis: all five retail code families survive original whole-profile persistence without changing unrelated players/profiles. Added a native regression linked to the actual raw engine: invalid input, all-mission, reversible mission/single-reward toggles, idempotent reward sets/upgrades, actual weapon/dossier and multiplayer selectors, 166-byte save, exact backup and fork/exec reload. `scripts/test_secret_unlocks.sh` passes 118 parent and 32 child checks; registered in engine verification. No engine/app binary change or new exports.
- Simulator original NPQA keyboard accepts the remaining all-mission/reward-set/single-reward/upgrade families, including a space. Original Save Codename writes mission mask 0xfff, expected reward/upgrade words, and exact preceding backup. Stop, process termination, relaunch and original profile load retain final mission selection, Gold P2K/stunner upgrades and Uplink scenario. Protected unrelated profiles are unchanged. `evidence/secret-unlocks/result.json`, captures and `build/tests/secret-unlocks-run.log`.
- Exact engine/dependency/build identity remains the post-0035 artifact in `evidence/action-audio-sessions/build-identity.json`; engine pin 8779cf79ff623b83b53b9acf9c0b0cd6639b75ab and dependency hash f2ae8ce569ba6fe8676fdfcdc4bd4a4c9a490aa483d1d661afed2dd63742b08e. Prior same-artifact full engine/build gates remain scoped evidence; only the new focused native test reran.
- R19 remains partial for physical input and signed-device persistence. Campaign, remaining multiplayer/display and physical acceptance remain open. Mac is unlocked with the task-owned temporary keep-awake assertion. Goal stays active; next independent step is an objective multiplayer match on a second map, then the original NPRUN earned campaign path.


## 2026-10-29 03:41 UTC — loaded-profile assist mismatch reproduced and repaired

- A diagnostic original NPQA Uplink/Fort Knox match with six bots reaches objective scoring and Phoenix 10-6 results. Repeated player hit flashes without health loss led to inspection of NPQA's protected CHET=01 despite native OFF. This match is not unassisted acceptance. NPRUN's CHET=00 and unchanged profile protect earlier campaign claims.
- Hypothesis: ApplyAssists clears OFF only when requested bits change, so an actual profile load can silently turn it on. Extended the native engine test to pause, encode/load the production CHET block and resume through two frames. Before: unowned and requested ON pass; default OFF and returned OFF both fail with applied=3. `build/tests/assist-profile/before-final.log`.
- Patch 0036 makes both supported app choices authoritative every frame once a runtime setter claims bit-31 ownership. Unowned standalone/replay engines retain original behavior; AllWeapons stays untouched. After: all four profile-load cases, normal on/off and Stop/join pass. `build/tests/assist-profile/after.log`.
- Unchanged CastleIndoors1 all 635 frames, 36-patch/83-file reconstruction, quick gates and both iOS build lanes pass. Full engine suite and unsigned package are running, then protected simulator install and loaded-profile OFF verification. Decision 0022. No new physical acceptance; goal remains active.


## 2026-10-29 03:54 UTC — assist authority candidate verified

- Full `scripts/verify_engine.sh`, quick gates/both iOS builds, 36-patch/83-file reconstruction and unsigned Release package terminate PASS. New unlock-family gate passes within the full suite. Focused unchanged replay remains 635/635; the full eleven-recording baseline is still earlier scoped evidence.
- Protected all seven existing save files, installed the rebuilt phone app and verified installed/built binary hash 09c8e134d487c3eea9429d3cc229b4ad957ecbe4695663cdc67069c310cdfc68. Original NPQA load (stored CHET=01) with native OFF now loses health to guards and dies; Replay restores gameplay. Explicit native ON retains health under fire, then OFF restores death. Clean Stop and byte-identical profile hashes; both native choices end OFF.
- Unsigned package SHA-256 72c972ff92030830f28c83fa0fe8a2d819bd5a57442caa94a776a6c68f50c616. Identity and limitations: `evidence/assist-profile/result.json`; source base f72fbe6 plus patch 0036 and runtime ownership. No new bridge exports, profile format or progression change. Decision 0022 updated with completed evidence.
- Continue original NPRUN truck/courtyard/earned-results route and repeat objective multiplayer on the fixed build. Earlier Uplink points/results remain diagnostic because loaded QA immortality was active. No whole campaign or physical acceptance credited. Goal stays active; no build/test job remains live.


## 2026-10-29 04:19 UTC — original campaign retries on fixed candidate

- Resumed original NPRUN/Operative Exchange on 638caa5 with both native assists OFF. Subsequent boarding attempts missed the truck, and an on-foot attempt crossed the security arch with normal damage before going over the road edge. No new objective/results save is credited. Failure, Replay and original Pause -> Restart recover; clean Stop works.
- The truck's timing after Restart remains uncertain; do not infer a core engine defect from these navigation failures. Next bounded check uses a fresh engine start and holds the native menu immediately after screenshots to prevent analysis time from consuming the boarding interval. The alternate exterior path leaves the truck after the first gate/right turn and uses shimmy/grapple, per the locally retained strategy guide.
- No build/test job is live. Installed artifact remains 638caa5 with the prior recorded hash; all baseline gates remain passed on scope. `evidence/campaign-truck/current-attempt.json` carries attempt detail. Keep the goal active and continue earned progression plus the independent multiplayer/device matrix.


## 2026-10-29T04:55:09.641913+00:00 — exterior ledge route extended

- On fixed source 638caa5 with original NPRUN/Operative and both native assists OFF, fresh Start/Restart return to spawn. Measured observations find the truck below the ledge; missed boarding is not an established timing defect.
- A direct on-foot route crosses the first arch, follows the bend through the broken fence left of the main bridge, triggers the original snow-slip cutscene and traverses the creep wall using the original controls. A shorter second exit reaches the outside corner/007 marker. Gap traversal still fails through navigation/falls; no whole mission or earned results save is credited. Private detail/capture: `evidence/campaign-truck/current-attempt.json`, `exterior-ledge-cutscene.png`.
- Clean Stop succeeds; all seven profile/backup hashes remain unchanged, including NPRUN 135a8a26…aba77. No source/build change or rerun of already-passed gates. Continue the independent Uplink match on the fixed artifact, then the first exterior pole/gap with shorter input. Goal remains active.

## 2026-10-29 05:37 UTC — native gameplay-clock pause repaired

- Hypothesis: Uplink subtracts the wall-clock interval held by the native menu even though frames are paused. A focused actual-engine regression confirms it: an 800 ms hold adds 0.810 s to `MPGame.TimeUnpaused` before the repair. Mission elapsed-play statistics share that clock; earlier frame/audio pause evidence did not cover it.
- Patch 0037 excludes the observed native hold from PSI gameplay time, retaining free-running host timestamps for file/stream timeouts and original replay arithmetic. Repeated requests, resume, Stop while paused and boot reset are covered. Afterward two boots hold PSI/MP time at zero delta, resume advances 31 hundredths and both Stop/join paths pass. Decision 0023, `build/tests/action-pause-clock-before.log`, `build/tests/action-pause-clock/after.log`.
- Complete native engine regression, quick/both iOS builds, 37-patch/83-file reconstruction, unchanged CastleIndoors1 all 635 frames and unsigned package validation pass. Installed/built phone binary matches fd6913a5…1c0a9; unsigned IPA 1247cd99…5c5. Exact source, dependency and artifact hashes are in `evidence/action-pause-clock/result.json`.
- Simulator Uplink/Fort Knox holds frame 15991 for at least 52 seconds and resumes countdown 1:58 -> 1:57. One human against six Phoenix bots verifies bot objectives/points, two human deaths, automatic respawn, +10 rounds pickup, Phoenix results and original Replay. Human frag and human satellite capture remain unverified. Both native assists OFF; clean Stop and all seven existing save/backup hashes unchanged.
- The Mac remains unlocked; the task-owned temporary keep-awake assertion was renewed. Continue original NPRUN Exchange through the exterior first pole/gap to earned results/save/relaunch. No whole campaign, full multiplayer, physical acceptance or causal clock explanation for earlier navigation falls is claimed. Goal remains active.

## 2026-10-29 05:47 UTC — post-0037 campaign checkpoint

- Committed pause-clock repair and completed evidence as a0c43b7. The installed binary remains the exact validated artifact. Task-owned temporary display/idle assertion renewed for four hours; no authentication setting change.
- Original NPRUN/Operative with native assists OFF restarts Exchange. First navigation attempt overruns the road bend and falls; original Replay recovers. A shorter turn reaches the main bridge, jump/left strafe reaches the exterior Action prompt, and original creep-wall traversal exits to the front shelf under the hanging hook. A later guard/fall death ends the second attempt. No engine defect, whole mission or earned results save is credited.
- Clean Stop returns to launcher. All seven profile/backup hashes remain unchanged; private route and exact next step are in `evidence/campaign-truck/current-attempt.json`. Inspect footing and the right turn around the outside corner before advancing; blind timed replay is unreliable when alignment differs. Goal stays active with campaign, human multiplayer frag/capture, remaining display and physical gates open.


## 2026-10-29T06:56:34.935270+00:00 — post-0037 truck and courtyard routes recovered

- Original NPRUN/Operative with both native assists OFF boards the supply truck, completes the first objective and automatically enters CastleCourtyard on unchanged installed source a0c43b7. Private captures and exact route notes: `evidence/campaign-truck/current-attempt.json`.
- Corrected route assumptions: the NPC beside the truck identifies as its delivery driver; the passage beside the truck is already open; the cellar and closed courtyard side door do not advance this observed route. Combat can clear both pavilion guards with the PP7 and recover an SG5. A later crouched route passes both unaware guards without firing and reaches the dolphin fountain with full health.
- Two later attempts reach the searchlight courts but end in patrol/combat deaths while locating the next staircase/door. These are navigation failures, not an established engine defect. Original Replay repeatedly recovers to a fresh CastleCourtyard checkpoint. No whole mission, earned result/save or whole campaign acceptance is credited.
- Current live state: fresh courtyard after Replay, full health, PP7 7/41, driver alive, no shots in current replay; native menu holds gameplay. Keep this checkpoint live. All seven profile/backup hashes remain byte-identical; no source/build changes or unnecessary rebuild/test reruns. Only the phone simulator is in use. Temporary keep-awake PID 95144 remains active.
- Next: repeat the documented truck-side arch and crouched pavilion/banner/fountain route, stay out of searchlights, identify the far staircase/door from cover, then progress to original earned results/save/relaunch. Independent human multiplayer frag/capture and remaining display/device gates stay open. Goal remains active.
