# NightPad status

Updated: 2026-11-04

## Current focus (2026-11-04)

Stability of the original build. Online play is researched and planned in
[NETPLAY-PLAN.md](NETPLAY-PLAN.md) but deferred.

Since the 2026-10-29 wrap-up the app runs on the owner's physical iPad Pro
12.9 (6th generation, iPadOS 27.0.1), signed with the owner's development
team. Merged in PR #2: UIScene lifecycle (iPadOS 27 refused the old launch
path), native-resolution borderless game window (patch 0039), audio kept
across engine handoffs and restarts (0040), audio held under the ⋯ menu
(0041), the blue icon and themed launcher, the import panel layout and the
Control Guide. The owner confirmed display, render resolution, controls and
level audio on the device.

On branch `codex/touch-system` (not yet merged):

- Touch layout editor rebuilt around grouped items (A/B/X/Y, White/Black,
  Start/Back move, resize and hide together), a Size slider and one overlay
  opacity. The owner's iPad arrangement is the tablet default.
- The game window is locked to landscape (0043) and re-aligned when native
  UI closes, the likely cause of the picture shrinking after the editor.
- Cheats menu with All Weapons and Unlock All Content (0042). Both are forced
  only while on and hand the game's own value back when turned off, so a
  profile's All Weapons is preserved.
- About screen redone with the repository and issue links.
- Start is blocked while a stopped session is still shutting down; it could
  otherwise start a second engine before the first joined.

Verified on this pass: host tests (input, touch layout and input, policies,
settings, presentation, contrast, data import and tools, diagnostics, saves
link, engine save, FMV audio), patch reconstruction, privacy, both iOS lanes
and the link check. iPadOS 27 simulator smoke: launcher, Start, ⋯ open/close,
group drag from the diamond's middle, empty-canvas drag ignored, opacity
saved and applied, Stop and menu Start again, audio thread present after
restart.

Not verified: the macOS-hosted engine tests (`verify_engine.sh`, master
volume, audio sessions, launch bridge, assists) cannot start on this Mac's
macOS 26.6.2; see known issues. All Weapons and Unlock All have not been seen
in play. The post-editor display fix still needs the owner's device check.

## Outcome

The autonomous goal loop is paused at the user’s request after a bounded
README and smoke-check wrap-up. The private-candidate gate remains incomplete. G00 and G01 are complete on their documented source
and data scopes. G02 has a working native baseline and is blocked on the
missing PAL movie set. The iPhone Simulator now runs the real game: imported
data loads, the action engine hands off to driving, and the Paris tutorial
renders with touch input. G03 still needs signed physical-device acceptance;
simulator execution is no longer a platform blocker.

## Verified

- Screenshot-led touch/menu review: Xbox diamond, aligned sticks, separate
  system keys, shared editor/input geometry, corrected safe-area margins and
  minimum targets. Root settings precede Data & Saves and Help & Feedback;
  Stop is last. Phone/tablet Exchange captures drove HUD clearance fixes.
  README and handoff paths are expanded. Decision 0024 records exact scope;
  physical comfort, drag/pinch and redesigned-editor larger text remain open.
- Native Audio now offers working master-volume choices. Actual final PCM
  verifies combined game/movie attenuation and exact mute while clocks keep
  advancing. Native 50% survives app relaunch; live mute/100% and clean Stop
  pass. Removing the redundant root heading keeps all seven actions visible
  on the phone at standard row size. Decision 0025 records exact scope.
- Current facf3fc reproduces the original NPRUN/Operative truck objective,
  automatic CastleCourtyard, searchlight laser/Bond Move and armor pickup.
  The touch route crosses the helipad and courtyard, enters the party with
  its new Rendezvous objective, and reaches the gallery. The live checkpoint
  was cleanly stopped for the requested wrap-up. Same-process Start returns
  the original title; touch Start opens the front end; final Stop returns the
  launcher. All seven existing saves and phone layout remain byte-identical.
  Both native assists remain OFF. No whole mission or earned results save is
  credited. Final app state is stopped at launcher.
- Final README links, complete quick suite, both iOS shell builds, link checks,
  38-patch/85-file reconstruction and privacy pass. Installed and rebuilt
  simulator binary hashes match the recorded facf3fc artifact. Exact local
  smoke evidence: `evidence/final-smoke/result.json`. Resume only when requested;
  campaign, multiplayer and physical-device acceptance remain incomplete.
- All three unchanged CastleExterior recordings pass on current engine source,
  matching 25,784 frames. This is replay evidence and route reference, separate
  from the live simulator campaign. Exact subset: private
  `evidence/campaign-truck/volume-campaign-result.json`.
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
  `ENOMEM` on the third start. Patch 0027 returns engine and timer stacks to a
  process cache when they are released and reuses the same in-window addresses
  on the next session.
- Ten action start/stop/join cycles pass. Resident memory grows about 2.4 MB
  per cycle after warm-up (224 MB to 248 MB over ten cycles).
- Fifteen action start/stop/join cycles pass with resident memory steady at
  264 MB after warm-up; ten driving cycles settle at 280 MB.
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
  stop/join/close from the menu. On the iPhone 17 Pro simulator it loads the
  real `filesys` archives, plays the title and intro, hands the launch page to
  `d:\driving.xbe`, and enters the Paris tutorial with the touch overlay visible.
  The final simulator build also reached the single-player mission list and
  loaded The Exchange into first-person gameplay; holding the left touch stick
  moved Bond and the right stick turned the camera.
- Stop Game now returns to the shell promptly in a live campaign mission. The
  shell keeps pumping SDL during teardown, so the engine can finish its current
  present callback instead of stalling for 30 seconds and reporting a timeout.
  A late join also reaps a thread that exits just after the timed wait.
- A second Start in the same process now reaches the title again. The action
  renderer was retaining its bound-index pointer across sessions and crashed in
  the first sky draw; it now invalidates that cache at graphics init and treats
  a missing index buffer as a reported draw miss instead of a null dereference.
- Stop/Start from the title renders the next title after the action runtime
  resets the backend's per-session GPU resource and command caches. Stopping from
  a non-title front-end page, such as the codename page, can still leave the
  next session black before the title; that remains open.
- The simulator now completes the action-to-driving switch by selecting Paris
  Prelude and enters the driving engine's Paris sniper view at 60 fps. Stopping
  from that driving mission can exceed 60 seconds in `Bond_CleanUp` audio-stream
  destruction; the driving-stop issue remains open.
- User-initiated Start now removes a stale `psiLaunch.bin` before launching the
  action engine, so reopening the app returns to the title or the saved
  profile's resume state instead of the previous driving Results page.
  In-process action/driving handoffs still preserve their launch page.
- The simulator renderer uses SDL's Metal backend through a narrow patch to the
  pinned SDL source. SDL 3.4.18 assumes the iOS device-family query on the
  simulator, where Metal exposes the host GPU instead. The build applies
  `patches/sdl3-ios-simulator-metal.patch` automatically; the device lane is
  unchanged. See `docs/DECISIONS/0014-simulator-metal.md`.
- Simulator paths are long enough to exceed two old Windows limits. The
  disc-path setting now keeps up to 1024 bytes, POSIX host paths use 4096 bytes,
  and a stale launch `saves` symlink is repaired only when its target is gone.
  The saves-link regression passes. `scripts/verify_patches.sh` reproduces 55
  files from the pin after `patches/0018-ios-long-paths.patch`.
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
- Menu actions that open a sheet (Touch Layout, Control Help, About,
  Diagnostics, Share Saves) now defer presentation until the menu has
  dismissed. Before that they silently did nothing while the game was on
  screen; alerts use the same route.
- The three-dot menu, the settings surfaces and the touch editor are held to
  the pinned SunPad and GalaxyPad implementations as the quality bar
  (`docs/DECISIONS/0012-donor-ui-benchmark.md`).
- Campaign objectives are inventoried for all nine action missions and their
  24 level parts, including the two out-of-wheel cut chapters, with the part
  lifecycle and the results-page save route; driving-mission objectives remain
  open.
- The touch editor can hide or show a control by long-pressing it; the choice
  survives save and relaunch and the live overlay drops hidden controls.
- Game Data & Saves can import `Documents/NightPad Import` with one tap, so
  the prepared tree no longer has to go through the system picker; both import
  paths open the data panel so progress and Cancel Import are visible.
- External texture overrides are decided: the engine's DDS replacement belongs
  to the D3D9 backend this port does not compile, no Xbox texture-pack scene
  exists to consume it, and the bounded SDL/Metal port is planned but deferred
  (`docs/DECISIONS/0013-texture-overrides.md`).
- The full engine suite passes on the current tree (`scripts/verify_engine.sh`
  at `480ac5a`), and `scripts/verify_quick.sh` passes alongside it.
 - Open issues and the non-issues that look like bugs are collected in
   `docs/KNOWN-ISSUES.md`.
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
- Diagnostics now include the active render size, display options, assist state
  and the last twenty shell events (launch, import, engine start/stop, handoff,
  native pause/resume, errors). Paths and credential-shaped values are still
  redacted, and the report stays local until shared.
- The shell builds in Debug and Release lanes. A Release build reports
  `build_configuration=performance/release`, checked by
  `scripts/test_release_diagnostics.sh`, which boots and shuts down a single
  simulator itself.
- Overlay, editor and help text now scale with Dynamic Type using font metrics
  capped so labels still fit their controls; verified at XXXL on the simulator.
- Game Data > Share Saves exports the save files through the system sheet
  (Copy, Save to Files), giving players a backup path now that the engine writes
  through the durable Saves link.
- Game Data > Import Saves opens the document picker and copies the chosen
  files into Saves, asking before replacing a name that already exists. The
  picker selection itself is a manual step.
- A real 166-byte PLRS profile (`BOND.dat`) survives app relaunch and loads
  The Exchange. Its decoded mission mask is the initial `0x3`, with all scores
  zero; this proves profile persistence, not earned campaign progression.
- Engine profile writes now use a flushed hidden stage and atomic replacement,
  retaining the previous `.dat.bak`. Twelve injected I/O scenarios and two
  forcibly killed writers preserve a complete old/new profile. The original
  Save Codename flow changed an isolated NPQA profile from Classic Bond to
  NightFire and reloaded that setting after app relaunch. Existing saves stayed
  byte-identical. See decision 0015 and `scripts/test_engine_save.sh`.
- An original mission Secret Unlock was entered with the touch keyboard on
  NPQA, saved, reloaded after an app update/relaunch, and reversed to the exact
  prior bytes with the same code. An invalid entry and subsequent save left
  the profile unchanged. This covers one mission-toggle family on simulator;
  other unlock families and physical acceptance remain.
- Control colours come from one shared palette; the test checks each control's
  actual lettering, dark on the face keys and white on the graphite keys, at
  4.5:1 or better.
- A host render-cost pass plays Mission 1 at 1x, 2x and 3x and finds the same
  ~50 fps cap at all three (339-348 draws), so higher targets run but the
  Mac is not resolution-bound. Device performance still decides the default.
- Touch auto-hide now depends only on the controller that owns the touch
  player's port. A second player's controller can no longer take player one's
  touch controls away.
- The touch overlay's accessibility order is explicit: movement, shoulders,
  system buttons, look, then the face buttons, with the menu last. It used to be
  reverse subview order.
- The layout editor uses the same order, so editing with VoiceOver visits the
  controls predictably too.
- Secret Unlocks is inventoried: 52 codes in five families (all missions, one
  mission toggle, reward sets, single rewards, upgrades) applied to the codename
  being edited. The device test plan is in the campaign inventory; the codes
  themselves stay out of the repository docs.
- Multiplayer map rules are mapped: Ravine disables AI bots and mini vehicles,
  every map uses standard drone tuning, and no source check ties a mode to a
  map. Runtime confirmation on two maps is still needed.
- The multiplayer unlock matrix is mapped: seven of thirteen modes and twelve
  of twenty-nine characters are default; the rest plus Explosive Scenery are
  reward-gated, and medals and Secret Unlocks feed the same reward mask.
- Display offers a vertical field of view of 60° (original), 70° or 80°; the
  value persists and is written to the engine, which clamps 30-120 and leaves
  scopes unchanged. Visual checks at each value remain.
- Native pause is proven to gate audio as well as frames: action pause reports
  SFX and streams paused then resumed, and driving pause reports the sound
  manager paused then resumed.
- Multiplayer match rules are mapped: duration 1-10 then 5-minute steps to 60 or
  unlimited; points/lives 1-10 then 5-point steps to 120; Arena and Team Arena
  report victories, the scored modes report points.
- Missing sub-level intros are tolerated: the CastleExterior recording requests
  CastleCourtyard's absent movie, logs "cannot open" and still matches every
  frame. NightPad writes `Region=NTSC` to match the supplied 30 fps bundle.
- `scripts/verify_patches.sh` now proves the tracked patch series reproduces
  the vendor tree: every patch applies to a clean worktree at the pinned
  revision and 57 files match byte-for-byte. It is part of the quick pass.
- `scripts/package_device_app.sh` builds the Release app and writes a 3.6 MB
  unsigned IPA with no loose dylibs; signing and installation remain the device
  handoff step.
- `scripts/test_clean_shell_build.sh` rebuilds both shell lanes from empty
  CMake/Xcode trees and still passes the device link check.
- The full engine suite passed end to end at `3e7a133`: lifecycles, both pauses
  with audio, assists, early stop, transitions, handoff and the round trip.
- `scripts/check_privacy.sh` verifies the repository tracks only source: no
  ref/build/vendor/evidence trees, and no retail, movie or binary artefacts. It
  runs in the quick pass.
- The privacy gate also rejects networking APIs in `apple/`; About-page links
  open in the browser, and diagnostics stay local until shared.
- Control Help no longer conflates driving with mounted views. Driving keeps its
  gas/brake/handbrake card; mounted views have a separate card that names the
  POV variations across the eight configurations.
- The shell pauses the engine when the app leaves the foreground and resumes
  only the pause it created; a player pause or an open native panel is left
  alone. The rule is unit-tested; hearing it needs a device.
- Cancelling a game-data import no longer blocks later imports. A new import
  starts a fresh transaction, the cancelled one leaves no stage, and the shell
  reports cancellation as information rather than an error.
- Bot setup is inventoried: six slots with playing, accuracy, aggression, speed,
  health 50-300, reaction/recovery 50-200 and side-dependent personalities;
  higher-index characters use fixed stats.
- [CANDIDATE.md](CANDIDATE.md) is the draft candidate manifest: identity fields
  to freeze, support matrix, verified evidence, known issues and the device
  next step. It is not an acceptance claim.
- [PERFORMANCE-BUDGET.md](PERFORMANCE-BUDGET.md) fixes the measurement routes
  and provisional numeric budgets before optimization: 15-minute action and
  driving runs, warm repeats, a 60-minute mixed session, cadence, frame-time,
  memory, thermal, latency and audio targets.
- `scripts/candidate_identity.sh` prints the manifest identity fields (commit,
  pin, lock and patch hashes, data/content/package hashes) and `--require-clean`
  refuses to freeze an uncommitted tree.
- The identity script also verifies every pinned checkout — engine, GalaxyPad,
  SunPad, extract-xiso and the FFmpeg submodule — and fails on drift.
- `scripts/summarize_perf.py` turns engine PerfLog output into JSON
  (mean/median/min/max fps, working and waiting milliseconds) with `--skip` for
  loading samples and a hard failure when a log has none.

- A fresh NPRUN codename was created through the original keyboard/save UI.
  Unassisted Paris showed its intro, driving handoff, sniper/fire input,
  failure, Replay and Quit back to action. The failed runs kept its initial
  profile byte-identical; no earned campaign progression is credited.
- Two one-minute Arena matches on Skyrail with one touch-controlled human and
  all six bots reached the original debriefing. The second began through Replay;
  results show bot victories/deaths and two human deaths. Other maps/modes and
  physical ports remain. Evidence: `evidence/multiplayer/arena-skyrail/`.
- Widescreen now writes numeric `1/0`, which both engine parsers require. The
  real action parser passes 4:3/16:9, FOV/FPS/disc-root and reload tests. Patch
  0029 reloads cached action settings before each session; a simulator process
  logs `widescreen=1` then `0` across Stop/change/Start. Both iOS lanes, native
  action build/lifecycle and the rebuilt unsigned device package pass their
  relevant checks. Full-window stretching remains separate and unresolved.

## Current uncertainty and blockers

- R18 aspect fitting is repaired on simulator; the remaining display matrix
  and physical acceptance are still unverified.

- The simulator now stops both engines cleanly: Stop Game from the Paris
  driving session joins in 1.7-3.7 s. The former 60-second hang came from the
  speech `.spe` big file failing to open at an exactly-260-character host path;
  the driving engine's `CreateFileA` now resolves into a host-sized buffer
  (patch 0018) and the stream layer recovers from an open that fails (0022).
- A second Start in one app process now reaches the title: the game-flow stack
  is reset to `GAMEFLOW_BOOT` at each session start (0024), so `bootup_bootup`
  and the front-end load run again instead of inheriting `GAMEFLOW_GAME`. Three
  consecutive cycles and the Paris handoff pass on the simulator. The attract
  trailer `073a0048.xmv` is absent from the supplied 30 fps bundle and shows a
  black page that A skips.
- Engine handoffs no longer open their window under the shell: `switchEngine`
  lowers the shell window to the normal level while the target engine opens its
  window and raises it again afterwards. The Paris tutorial renders, the right
  trigger fires, Mission Failed and REPLAY TUTORIAL work, and Stop returns in
  1.7 s.
- Repeated sessions no longer leave a window without its Metal view. The SDL
  GPU backend released the previous window's device claim before destroying it
  (patch 0026), and the driving engine now clears its process-global D3D device
  token at each session start so it creates a device for the new window. A
  complete action -> driving -> Stop -> action -> driving route renders the
  second Paris intro and reaches Mission Failed in the same process.
- A mission followed by Stop and Start no longer crashes: the action engine's
  sound banks were freed at the start of the next session, after the heap they
  pointed into had been replaced. `SFXShutdown` unloads them at session cleanup
  (patch 0025); a Paris mission, Stop and a fresh Start reach the title with no
  crash report.
- GalaxyPad's touch geometry now carries an Xbox finish: graphite sticks and
  shoulders, a dished D-pad cross, molded highlights, four face-button colours
  with dark lettering, and White/Black/Back icons. The live overlay uses each
  control's saved opacity. Tablet controls use GalaxyPad's fixed point sizes.
  The layout version is 3, so older saved layouts fall back to the defaults.
  The 44-point menu keeps Start/Stop in the root list and groups Display,
  Controls, Data & Saves, Enhancements and Help & Feedback without scrolling.
- No valid Apple code-signing identity and no connected physical device were
  visible at inventory time. This blocks signed physical-device acceptance in
  G03, G06 and G12; independent build/UI work continues.
- The supplied image lacks the PAL `25_fps` bundle and the
  `073f0048.xmv` movie required by one recording. The alias is an explicitly
  labeled compatibility experiment, not a verified PAL replacement.
- Physical pointer, Metal, SDL and lifecycle behavior is unverified.
- G04's game-state, file-handle, GPU-cache, worker-thread and stack-
  reuse contract passes fifteen action cycles, ten driving cycles and the
  mixed round trip on macOS. Physical-device lifecycle evidence remains
  blocked by the missing signing identity and connected hardware.

## Next step

Physical acceptance is the gate. Run `scripts/device_handoff.sh --install` once
a signing identity and a trusted device exist, then work the checklist in
[DEVICE-HANDOFF.md](DEVICE-HANDOFF.md): the probe, the data import and save round
trip, touch and controller sessions, Secret Unlocks, display modes and the
fifteen-minute stability runs.

Aspect fitting now preserves the selected 4:3/16:9 frame inside the window's
safe area with black bars. Phone/tablet action titles, driving HUDs and the
corrected tablet widescreen scope have simulator evidence. The real driving
XAPI test also fixes the dashboard flag's bit encoding. Decision 0017 records
these changes and the narrowed missing-attract-movie fix, which restores the
635-frame replay that the earlier generic skip had broken.

The fresh post-fix eleven-recording replay recheck passed all 208,364 frames.
No replay runner remains live. SpaceStationD still needs the missing movie data.

Native movie pause/stop is repaired in patch 0033. Actual SDL voice/clock
regressions and two native intro cycles pass. Simulator action holds its clock;
driving holds presented frames 77 and 624, resumes, and stops while paused in
1.825 seconds. The quick gates, both iOS build lanes and unsigned Release
package pass; the unchanged 635-frame replay still matches. See decision 0019.

Patch 0034 resets the interrupted loader phase and cached launch page at each
action boot. The before/after native regression, simulator movie Stop/Start
title and mixed native round trip pass. See decision 0020.

The original Paris failure -> Quit route returns to the action mission menu
through a newly read handover page; NPRUN remains unchanged. Next: continue
NPRUN earned mission/results save and relaunch, plus objective-mode and
remaining multiplayer map coverage.
Individual campaign objectives do not write a profile save. Keep the fifteen-cycle
action gate, ten-cycle driving gate, mixed round trip, pause, transition, handoff
and data-import checks as regressions.

Verification entry points are `scripts/verify_quick.sh` (host logic, both
shell builds, device link contract) and `scripts/verify_engine.sh` (lifecycle,
pause, transition and handoff).


The Mac is unlocked and simulator control works. NPRUN was protected and
verified unchanged, the prior attempt cleanly stopped, and the patch-0035 app
installed. The live original UI NPRUN run completed the truck/crouch objective and
automatically entered CastleCourtyard with both native assists off. Three
courtyard gameplay deaths exercised Replay; the attempt ended with clean Stop.
The whole mission and earned results save remain unverified.
`evidence/campaign-truck/result.json` records the boundary.

Patch 0035 repairs the later-boot action audio-buffer registry overflow. The
actual SDL/cache/mixer test passes fifteen boots and 2,880 buffers; fifteen
real action lifecycle cycles join without overflow. Both iOS builds, quick
checks, focused replay and the unsigned package pass. Full post-fix native engine
verification passes. The new build is installed; its hash matches the verified artifact. HRTF/reverb and physical audio acceptance remain outstanding.

Original Secret Unlocks now have five-family native coverage (118 checks plus
32 fresh-process reload checks). The isolated NPQA original keyboard/save path
accepts all-mission access, reward sets, an individual reward toggle and upgrades.
A new app process reloads final-mission access, Gold P2K/stunner upgrades and
Uplink selection. The 166-byte profile has expected masks and an exact previous
copy; NPRUN and all unrelated saves are unchanged. Physical entry/persistence
remain open. See `evidence/secret-unlocks/result.json`.


Patch 0036 fixes a saved profile silently overriding native assists OFF. Actual
CHET-load before/after tests pass, with standalone/replay ownership preserved.
The updated simulator loads the stored-immortal QA profile and takes damage/dies
with native OFF; Replay, explicit ON protection and OFF restoring death pass.
All profile hashes are unchanged and native choices are restored OFF. Complete
native engine regression, quick/both iOS lanes, unchanged 635-frame replay,
36-patch/83-file reconstruction and unsigned Release package pass. Decision 0022
and `evidence/assist-profile/result.json` record that installed build.
The earlier Uplink/Fort Knox scoring/results run is diagnostic only because it
exposed this bug; repeat it on the repaired build for unassisted acceptance.


Patch 0037 repairs a gameplay-clock gap in native pause: held action frames no
longer consume Uplink match time or mission elapsed-play time. The actual-engine
regression fails before and passes after across resume/paused Stop/two boots.
Simulator Uplink holds its countdown through at least 52 seconds in the native
menu (1:58 -> 1:57 on resume), then verifies six-bot objectives/points, human
death/respawn, ammo pickup, results and Replay with native assists OFF. Human
frag/capture and full multiplayer acceptance remain open. Clean Stop preserves
all seven save files. Full engine, quick/both iOS builds, 37-patch/83-file
reconstruction, focused unchanged 635-frame replay and unsigned package pass.
Decision 0023 and `evidence/action-pause-clock/result.json` record that scoped
build. Current candidate identity is in `evidence/master-volume/result.json`.
Continue NPRUN earned campaign/results save and relaunch.

Patch 0038 adds native master volume without changing the original game mix
at 100%. Full native engine verification, actual PCM/setting tests, final both
iOS builds, 37 bridge exports, 38-patch/85-file reconstruction, unchanged
CastleIndoors1 all 635 frames and unsigned Release package pass. Full quick
passed before the final root-heading/inline-group-only UI delta; final phone
screenshots and both shell builds cover that delta. The temporary keep-awake
assertion is renewed; authentication settings are unchanged. Physical audio,
remaining campaign/multiplayer/display and signed-device gates remain open.
