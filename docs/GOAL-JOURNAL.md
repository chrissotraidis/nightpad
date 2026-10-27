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

