# NightPad status

Updated: 2026-10-27 14:43 UTC

## Outcome

The goal loop is active. G00 and G01 are complete on their documented source
and data scopes. G02 has a working native baseline; G03 has passed the data-free
simulator probe and remains blocked on physical-device access.

## Verified

- Project root: `/Users/chrissotraidis/GitHub/nightpad`.
- Nightfire, GalaxyPad, SunPad and extract-xiso are checked out at the exact
  revisions in `config/dependencies.lock.json`.
- FFmpeg is at the engine's pinned commit `8ae0b34901ba60a802f183ee75a250a9fc3e09a5`.
- Xcode 26.6 build 17F113 is selected, with iPhoneOS 26.5 and macOS 26.5 SDKs.
- The supplied image is one physical 2,063,740,928-byte file. Both `ref` and
  `REF` names resolve to it. Its SHA-256 is recorded in local evidence.
- The image listing contains the required `eurocom/`, `driving/`,
  `default.xbe` and `Driving.xbe` entries and no traversal or absolute member
  paths.
- Pinned FFmpeg for `macos-arm64` built after setting the Xcode macOS SDK.
- Both original engines and both test executables build as arm64 macOS
  binaries. The 200,000-operation game-window probe passed with zero
  differences, and the fused-operation audit found only the 12 expected sites.
- Eleven of 12 action recordings pass every frame (208,364 frames) using an
  isolated 30 fps to 25 fps media alias. `SpaceStationD` stops at frame 11,343
  because the supplied image has no `eurocom/25_fps/073f0048.xmv`.
- Mission 1 drove headlessly to tick 9,000 twice with 16 frame dumps and a
  381,193-line sound trace each. The traces are byte-identical; the frame
  comparison differs by five pixels, within the documented Metal scatter.
- The iPhone simulator passed the 4 GB pointer/heap/thread probe, a Metal
  shader/readback fixture and FFmpeg XMV video/audio decoding.
- The unsigned iPhoneOS arm64 probe builds and links with deployment target 16.
- Both complete engines compile and link as separate iPhoneOS arm64 app
  targets. A relocatable-object isolation pass links them into one combined
  iOS executable with two engine thread entries and two launch-callback setters.
- The launch seam now hands the 3,072-byte page to an in-process coordinator
  and ends only the requesting game thread. A native pthread test confirms the
  page and image identity, no child process, and continued process execution.
- iOS SDL is now linked statically. The combined engine executable has no
  loose SDL dylib dependency; a clean bundle still needs to prove no stale copy
  is emitted.
- Both iPhoneOS engines now bind the pinned FFmpeg codec/demuxer/utility
  archives statically. The combined engine link has no FFmpeg dylib dependency.
- A real action start/window/stop/join harness reaches the existing cleanup
  path. Moving GameWindow and HostPosix into one shared runtime fixed the
  localized shader allocator crash. Three cycles join and settle on the same
  Cocoa/libdispatch thread pool; no engine worker remains visibly alive.
- The driving engine starts Mission 1 and completes its normal cleanup on
  cooperative stop. Its DEFAULT.XBE request reaches the in-process callback;
  closing the window before joining lets the cleanup complete and the thread
  join.
- The combined driving-to-action harness passes after deferring the action
  movie and launch-option singletons. Driving requests DEFAULT.XBE, closes and
  joins; action starts from the saved page, closes and joins.
- The same combined harness now triggers action's existing psiLaunchDriving
  seam and completes action-to-driving in the opposite direction.
- Repeated driving launches now work. The second boot re-arms the game heap,
  stops and rebuilds the file-system workers, and explicitly reconstructs the
  session-scoped static containers (EAGL pools, stream locale, input lookups,
  Simulation, reference counters, audio, physics, CARP, grid, targeting, AI
  vehicles and action queues) after the old heap is gone.
- Thread stacks are reserved from the image's in-window arena rather than the
  fragmented general window, so repeated launches no longer fail with
  `ENOMEM` on the third start.
- Ten action start/stop/join cycles pass. Resident memory grows about 2.4 MB
  per cycle after warm-up (224 MB to 248 MB over ten cycles).
- Ten driving start/stop/join cycles pass. Resident memory warms to about
  296 MB and the tenth cycle is lower than the ninth.
- Ten mixed driving/action cycles pass: 20 launch requests, both directions,
  every thread joined, and the settled OS thread count stays at eight to nine.
- The image is Xbox title `0x45410026`, "007: Nightfire", version 1, region
  mask `0x7`, with only the `30_fps` movie bundle present.
- The driving/POV control definitions were safely decoded from `misc.viv`:
  eight POV configurations, one Driving configuration and a separate front-end
  map.
- G05 started with a portable app path service and transactional game-data
  importer. Data, saves, launch state, caches, diagnostics and Documents are
  separate; imports use private staging, free-space preflight, manifest
  identity, required-tree validation, cancellation, atomic activation and
  previous-data retention. Saves are never touched. The native test covers
  invalid input, symlinks, cancellation, failed activation, replacement,
  rollback data and stale-pointer recovery.
- The G05 core compiles into the iPhoneOS probe target.
- G05 now has a native landscape `NightPadShell` app target. Simulator and
  device builds succeed. The persistent three-dot menu, data status/import
  panel with progress/cancel/previous-data cleanup, app-pause card, About card
  and diagnostics share entry render and are reachable.
- Simulator screenshots verify the home, menu and data-panel states. The app
  exposes its Documents directory to Files for prepared-folder import.
- The iPhoneOS shell now links the combined engine archive, static SDL,
  FFmpeg and SPIRV-Cross. Its device binary contains the action engine bridge
  and driving start, and the shell has an engine-host wrapper that prepares a
  private settings.ini from the active game-data path.
- The shell now has a live Start/Stop path: it prepares the active data root,
  starts the action engine, pumps SDL events from a 60 Hz host timer, keeps a
  transparent touch-through overlay above the game window, and requests
  stop/join/close from the menu. This path is device-build verified; running it
  still requires a signed physical device because the simulator has no SDL GPU.
- Native pause now lives at the engine frame boundary: action SFX and streams are
  suspended, frames stop advancing, and resume restores them. The shell's App
  Pause enters this state and Back to Game resumes it; the action pause frame
  test passes.
- Opening native menu/pause surfaces now pauses the engine and suspends input;
  pad and keyboard reads answer neutral and pointer deltas are discarded until
  the surface closes. The shell exposes the input bridge in the device link.
- Diagnostics now generate a local report with app/build identity, data and
  engine state, path classes, thread count and resident memory. Home paths and
  app-container UUIDs are redacted, credential-looking values are removed, and
  the report is presented for review with an explicit Share action. Nothing is
  uploaded automatically. Simulator review screen and device build pass.
- The simulator share sheet exposes Save to Files and Copy for the reviewed
  report; a generated report was read back from `Library/Logs/NightPad` and
  contains no home path, container UUID or game/save content.
- About NightPad is now a native page with version, product identity, source and
  interface-donor links, non-affiliation/game-data notices and accessibility
  identifiers. It renders in the simulator and is included in both app builds.
- A synthetic prepared-data folder imported through the shell's real
  validation/staging/activation path in the simulator. The active identity and
  files survived relaunch, and a pre-existing save file was unchanged.
- G06 started with `NightPadInput`: four Xbox-format ports, touch/controller
  source merger, short-tap edge latching, dead zones, trigger thresholds and
  release-before-reacquire for newly acquired controllers. Native tests pass and
  the core compiles into simulator/device shells.
- Added `NightPadTouchLayout`: independent phone/tablet defaults, normalized
  safe-area geometry, 44-point minimum clamping, opacity bounds, reset and atomic
  versioned persistence. Unknown/malformed layouts are rejected without
  replacing the active model.
- The touch-layout editor now renders the authored controls with Xbox labels and
  colours, supports drag and pinch with 44-point clamping, and offers Cancel,
  Save and a confirmed Reset. On the iPhone 17 simulator Save wrote
  `Controls/layout-phone.txt`, relaunch rendered a hand-edited geometry, and
  Reset plus Save restored the defaults. The default face-button diamond was
  re-spaced after the simulator showed it collapsing under the size floor; a
  test now asserts overlap-free geometry at three landscape sizes.
- G06 now has the in-game path: touch samples become an Xbox pad (sticks,
  eight-way D-pad, analog LT/RT, face/shoulder/system buttons, five fingers at
  once), and a pass-through overlay renders the authored layout with press
  feedback, accessibility labels and controller auto-hide.
- Apple's GameController framework is the single physical authority. Player slots
  are session stable, LB/RB map to White/Black, triggers stay analog, and rumble
  returns to the port that produced it. A new engine patch lets the app publish
  each port and bypass SDL's own gamepads.
- The three-dot button is now a native UIMenu with Game, Controls, Game Data &
  Saves and Info submenus, following SunPad's menu shape.
- Controls now includes a native reference for on-foot, vehicle and menu
  mappings. Vehicle rows come from the game's own drivecfg/POV definitions
  (RT gas, LT brake, B handbrake, A/X/Y secondary actions); the game's eight
  schemes and its inversion/aim/crouch preferences remain engine-owned.
- App settings are versioned at `Application Support/NightPad/settings.txt`:
  touch-control visibility, controller auto-hide and rumble. Unknown keys and
  another donor's Nintendo preferences are ignored, bad versions are refused,
  and a toggle survives relaunch (verified with rumble on the simulator).
- The app now owns XBE hand-off in-process: the launch request stops and joins
  the running engine, then starts the named one from `psiLaunch.bin`. A macOS
  gate proves action to driving boots `paris_mis01` from the handed page, runs,
  and joins on stop; driving also gained a nonblocking poll, pause/resume with
  sound, a frame counter and its own pad/rumble bridges.
- The engine's relative `saves` folder is now a symlink to NightPad's durable
  Saves directory when the host prepares a launch state, so a new import or a
  rebuilt launch state cannot strand campaign progress.
- The action build now honors the documented `DumpFiles=on` option. A front-end
  boot dumps named data, and the dumped text bank yields the 18-entry campaign
  order and nine multiplayer map names, recorded in
  [CAMPAIGN-INVENTORY.md](CAMPAIGN-INVENTORY.md). Mission-to-script mapping and
  per-mission transitions remain.
- The Display menu exposes 1x-4x internal render targets, FXAA on/off and the
  game's widescreen option. They persist in NightPad's settings and are written
  to the engine's settings.ini at the next Start; a macOS run at 1280x960
  confirms the backend builds the larger target.
- The campaign media bundle is inventoried: the 30 fps set matches the seven
  action missions' intro and outro ids plus two menu loops, and driving movies
  live inside their mission VIVs. Multiplayer limits, modes, maps, weapon sets
  and Enviro-Mods are recorded in [MULTIPLAYER-INVENTORY.md](MULTIPLAYER-INVENTORY.md).
- Two optional assists now work: immortality and unlimited ammo, applied by the
  action loop each frame so a codename load cannot clear them. They are off by
  default, persisted, and must stay out of acceptance runs.
- The coordinator loop is proven in one process: action hands off to driving,
  driving hands back, and action restarts from the page driving wrote. All three
  phases join and advance frames (`scripts/test_engine_roundtrip.sh`).
- A device handoff exists: `scripts/device_handoff.sh` rebuilds and links the
  device shell, states exactly which prerequisites are missing, and can sign,
  install and launch once a team and trusted device are present. The session
  checklist is [DEVICE-HANDOFF.md](DEVICE-HANDOFF.md). The install path is
  untested here because this machine still has no identity or device.
- Online netplay is formally deferred (decision 0011): the reconstruction has
  no networking layer and the front end exposes only local multiplayer. The
  original split-screen, bots and port rules remain the supported multiplayer
  scope; R23 is not applicable.

## Current uncertainty and blockers

- No valid Apple code-signing identity and no connected physical device were
  visible at inventory time. This blocks signed physical-device acceptance in
  G03, G06 and G12; independent build/UI work continues.
- The supplied image lacks the PAL `25_fps` bundle and the
  `073f0048.xmv` movie required by one recording. The alias is an explicitly
  labeled compatibility experiment, not a verified PAL replacement.
- Physical pointer, Metal, SDL and lifecycle behavior is unverified.
- G04's game-state, file-handle, GPU-cache, worker-thread and stack-reset
  contract passes ten cycles on macOS. Physical-device lifecycle evidence
  remains blocked by the missing signing identity and connected hardware.

## Next step

G06 continues with the in-game touch overlay and the single controller
authority: render the authored layout during play, feed touch and physical pad
state through the mixer into the engine, and then run the device composition
and Files checks. Keep the ten-cycle lifecycle, pause and data-import tests as
regression gates.

Verification entry points are `scripts/verify_quick.sh` (host logic, both
shell builds, device link contract) and `scripts/verify_engine.sh` (lifecycle,
pause, transition and handoff).

