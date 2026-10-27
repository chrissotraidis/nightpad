# Test matrix

| Gate | Scenario | Target | Status | Evidence |
| --- | --- | --- | --- | --- |
| G00 | Public source pins resolve exactly | Host | passed | `config/dependencies.lock.json` |
| G00 | Full Xcode and both Apple SDKs resolve | Host | passed | `config/toolchain.json` |
| G00 | Code signing and physical-device availability | Host | blocked | No identity or device visible |
| G00 | Private data stays untracked and the app has no network path (R27) | Host | passed | `scripts/check_privacy.sh` finds only tracked source, no ref/build/vendor/evidence trees or retail/binary artefacts, and no networking API in `apple/`; About links open in the browser |
| G13 | Patch series reproduces the pinned engine | Host | passed | `scripts/verify_patches.sh` applies every patch to a clean worktree at `8779cf79` and matches 53 files byte-for-byte; linker map files are excluded as build output |
| G13 | Device package recipe | Host | passed for unsigned artifact | `scripts/package_device_app.sh` builds Release, packages `Payload/NightPadShell.app` as a 3.6 MB unsigned IPA, checks `Info.plist` and rejects loose dylibs; signing/install remains the handoff step |
| G13 | Clean shell build from empty trees | Host | passed | `scripts/test_clean_shell_build.sh` removes the CMake/Xcode build trees and rebuilds simulator and device lanes; the link contract still passes |
| G13 | Candidate manifest drafted (R30) | Host | partial | `docs/CANDIDATE.md` records identity fields to freeze, the support matrix, verified evidence, known issues and the device next step; not an acceptance claim |
| G13 | Candidate identity is machine-generated (R30) | Host | passed | `scripts/candidate_identity.sh` prints commit, tree state, engine pin, lock hash, patch-series hash, data/content hashes and package hash, and `--require-clean` refuses an uncommitted tree |
| G12 | Performance routes and budgets frozen before optimization | Host | proposed | `docs/PERFORMANCE-BUDGET.md` defines device state, 15-minute action/driving, warm repeats and a 60-minute mixed route, plus cadence, frame-time, memory, thermal, latency and audio budgets |
| G12 | Performance log summarizer | Host | passed | `scripts/test_perf_summary.sh` checks mean/min/max fps, working/waiting times, the requested cap and `--skip` trimming; a log with no samples fails |
| G12 | Background pause and foreground resume rule (R16) | macOS arm64 / iPhoneOS build | passed for policy | `scripts/test_background_policy.sh` proves only a playing, not-already-held engine pauses on background, only that pause resumes, and a manual pause is preserved; device behaviour remains |
| G01 | ISO is unique and unchanged | Host | passed | Local source manifest |
| G01 | Listing is contained and has required Xbox trees | Host | passed | Private ISO listing and guarded script |
| G01 | Validated extraction and activation | Host | passed | 55 files, 2,062,585,542 bytes, source hash unchanged |
| G01 | Xbox title/revision identity | Host | passed | Title 0x45410026, version 1, region mask 0x7 |
| G01 | PAL 25 fps media bundle | Host | blocked | Supplied image contains only 30_fps |
| G01 | Driving/POV definitions | Host | passed | 12 definitions decoded from misc.viv |
| G02 | Native Mac targets build | macOS arm64 | passed | Both engines and test targets link arm64 |
| G02 | Game-window pointer workload | macOS arm64 | passed | 200,029 checks, 0 differ |
| G02 | Floating-point audit | macOS arm64 | passed | 12 expected fused operations, 0 unexpected |
| G02 | Action replay corpus | macOS arm64 | partial | 11 of 12, 208,364 frames every frame matched |
| G02 | SpaceStationD replay | macOS arm64 | blocked | Missing 073f0048.xmv in supplied media |
| G02 | Driving baseline run | macOS arm64 | passed | Mission 1, 9,000 ticks, 16 frames, sound trace |
| G02 | Driving baseline repeat comparison | macOS arm64 | passed with known GPU variance | 16 frames each; 5 pixels differ; 381,193-line sound traces byte-identical |
| G03 | Signed app launch without debugger/JIT | iPhone/iPad | blocked | No device or signing identity |
| G03 | Device handoff prepared | Host | passed for build, untested install | `scripts/device_handoff.sh` builds and links the device shell, reports missing identity/device, and signs/installs/launches once both exist; checklist in `docs/DEVICE-HANDOFF.md` |
| G03 | Simulator pointer/linker probe | iPhone 17 / iOS 26.5 | passed | 200,029 checks, 0 differ at 0x100000000 |
| G03 | Simulator Metal fixture | iPhone 17 / iOS 26.5 | passed | MSL compile, dispatch, texture readback |
| G03 | Simulator XMV media fixture | iPhone 17 / iOS 26.5 | passed | WMV2 plus Xbox ADPCM decoded |
| G03 | Unsigned iPhoneOS build | iPhoneOS 26.5 | passed | Mach-O arm64, deployment 16.0 |
| G03 | Physical pointer/linker probe | iPhone/iPad | blocked | Same external dependency |
| G03 | Physical Metal/shader/media fixture | iPhone/iPad | blocked | Same external dependency |
| G04 | Complete action engine compiles for iPhoneOS | iPhoneOS 26.5 | passed | Mach-O arm64 app target |
| G04 | Complete driving engine compiles for iPhoneOS | iPhoneOS 26.5 | passed | Mach-O arm64 app target |
| G04 | Both isolated engine objects link in one iOS executable | iPhoneOS 26.5 | passed | Exactly two engine entrypoints exported |
| G04 | iOS SDL linkage has no loose dylib | iPhoneOS 26.5 | passed for combined link | Static libSDL3.a; no dylib dependency |
| G04 | iOS FFmpeg linkage is static | iPhoneOS 26.5 | passed for link | Three pinned archives; no FFmpeg dylib dependency |
| G04 | In-process launch request captures page without child process | macOS arm64 | passed | 3,072-byte page identical; requesting thread exits; process remains alive |
| G04 | Engine stop, worker-thread join and resource reset | macOS arm64 | passed | Heap re-arm; file-worker and action file-slot shutdown; explicit session-static reconstruction; ten action, ten driving and ten mixed cycles join |
| G04 | Cooperative game-loop stop reaches existing cleanup | macOS arm64 | passed in raw-link harness | Game_Main returns and thread joins |
| G04 | Repeated action start/stop/join stability | macOS arm64 | passed, 10 cycles | Every cycle joins; settled 7 OS threads; resident memory 224 MB to 248 MB |
| G04 | Symbol-isolated start/stop heap and shader boundary | macOS arm64 | passed | Shared GameWindow/HostPosix allocator runtime; no shader crash |
| G04 | Driving engine start and cleanup | macOS arm64 | passed | Mission 1 starts, cooperative stop runs GameLoop_CleanUp and Bond_CleanUp |
| G04 | Driving launch request completes established boundary | macOS arm64 | passed | Callback receives 3,072-byte page; close-before-join completes and joins |
| G04 | Driving-to-action live restart in one process | macOS arm64 | passed | Driving page request, close/join, action start from page, close/join |
| G04 | Action-to-driving request through psiLaunchDriving | macOS arm64 | passed | Action callback captures DRIVING.XBE; window and thread join |
| G04 | Repeated mixed transition soak | macOS arm64 | passed, 10 cycles | 20 launches; both directions; real Boot_GetPTPData page; all joins; settled 8-9 OS threads |
| G04 | Ten repeated driving sessions | macOS arm64 | passed | Every cycle joins; resident memory warms to about 296 MB and the tenth cycle is lower than the ninth |
| G04 | In-process action-to-driving handoff boots the target | macOS arm64 | passed | `scripts/test_engine_handoff.sh`: action requests `d:\driving.xbe`, joins; driving reads the 3072-byte page, boots `paris_mis01`, requests `D:\DEFAULT.XBE` on stop and joins |
| G04 | Action, driving, then action again in one process | macOS arm64 | passed | `scripts/test_engine_roundtrip.sh`: action hands off to driving (its page read), driving hands back, action restarts from the handed page and runs; all three phases join |
| G04 | Driving simulation pause and resume | macOS arm64 | passed | `scripts/test_driving_pause.sh`: frames held while paused, advanced after resume, clean join |
| G05 | Native pause gates audio (R15) | macOS arm64 | passed for both engines | Action pause reports SFX and streams paused then resumed; driving pause reports the sound manager paused then resumed, alongside the frame holds |
| G04 | Stop requested during engine boot | iPhoneOS 26.5 build | implemented, unverified on hardware | The shell holds the stop until the active engine advances a frame (180 s fallback) because cleanup from a half-built engine crashed in testing; menu shows "Stopping After Load…" |
| G04 | Engine stop during boot joins cleanly | macOS arm64 | passed | `scripts/test_driving_early_stop.sh` at 2 s (frames 0) and 8 s (frames 3577), plus the action lifecycle at a 1 s stop: every thread joins and the process exits 0 |
| G04 | Full engine suite regression | macOS arm64 | passed | `scripts/verify_engine.sh` at `3e7a133`: lifecycles, action/driving pause with audio, assists, early stop, transition, handoff and the action-driving-action round trip all pass |
| G04 | Ten repeated action sessions | macOS arm64 | passed | File slots close per session; device-scoped buffers are reused; every cycle joins; settle 248 MB |
| G04 | Load-time initializer ownership | macOS arm64 | passed for transition | Fmv and LaunchOptions deferred; remaining graphics initializer is compatible |
| G04 | Action to driving and return transitions | macOS arm64 | passed, 10 cycles | `scripts/test_engine_transition.sh`; iPhoneOS execution remains device-blocked |
| G05 | Separate app data, save, cache, launch and diagnostic paths | macOS arm64 | passed | `NightPadPaths` unit coverage; directory creation and layout asserted |
| G05 | Transactional prepared-data import | macOS arm64 | passed for core | `scripts/test_data_import.sh`: preflight, staging, validation, cancel, atomic activation, replacement and rollback retention |
| G05 | Shell prepared-data import and relaunch | iPhone simulator | passed with synthetic fixture | Real shell import path; active tree and identity survive relaunch; existing save unchanged; production Files picker still needs a retail package |
| G05 | Shell import of the real prepared game data | iPhone 17 simulator / iOS 26.5 | passed | 56-file, 1.9 GB prepared tree imported through validation/staging/activation to identity `data-a3c98ab965ac41e559ac`; relaunch reports ready; a re-import left `Saves/slot1.sav` byte-identical; evidence `evidence/ios-shell/data-ready-real.png` |
| G05 | Production Files picker presentation | iPhone 17 simulator / iOS 26.5 | partial | Import action opens the system folder picker; navigating and choosing the prepared folder is still manual because the picker's remote UI is not scriptable here |
| G05 | Game saves routed to the durable Saves directory | macOS arm64 / iPhoneOS build | passed for wiring | The launch state's relative `saves` folder is a symlink to the app's Saves directory; `scripts/test_saves_link.sh` proves write-through, idempotence and refusal to replace an existing real folder. A real in-game save is still needed |
| G05 | Save export through the share sheet (R11) | iPhone 17 simulator / iOS 26.5 | passed visual smoke | Game Data > Share Saves opens the system sheet with the save files and offers Copy and Save to Files; evidence `evidence/ios-shell/share-saves.png`. Restore/import of saves is not built |
| G05 | Save restore through the document picker (R11) | iPhone 17 simulator / iOS 26.5 | partial | Game Data > Import Saves opens the picker; selected files copy into Saves, with a confirmation before replacing existing names. Picker selection and the collision prompt are not scriptable here, so end-to-end restore is manual |
| G06 | Four-port Xbox input mixer | macOS arm64 / iPhoneOS build | passed for core | `scripts/test_input.sh`: short taps, edges, dead zones, triggers, source merge, release-before-acquire and port isolation |
| G06 | Versioned touch-layout model | macOS arm64 / iPhoneOS build | passed for core | `scripts/test_touch_layout.sh`: phone/tablet defaults, safe-area/44-point clamp, overlap-free defaults, round trip, reset, unknown rows and bad versions |
| G06 | Touch-layout editor save/reset/relaunch | iPhone 17 simulator / iOS 26.5 | passed | `--open-touch-layout`; Save wrote `Controls/layout-phone.txt`, relaunch rendered the saved geometry, Reset restored defaults and Save persisted them; evidence `evidence/ios-shell/touch-layout-editor.png` |
| G06 | In-game touch overlay and controller UI | iPhone/iPad | unverified | Editor only; no gameplay overlay, controller authority or physical run yet |
| G06 | Touch samples to Xbox pad and simultaneous input | macOS arm64 / iPhoneOS build | passed for core | `scripts/test_touch_input.sh`: stick vectors, eight-way D-pad, analog trigger depth, shoulder/system bits, five simultaneous touches and newest-finger ownership |
| G06 | Controller slot reconciliation | macOS arm64 / iPhoneOS build | passed for core | `scripts/test_controller_slots.sh`: stable slots, free-slot reuse, sole-controller reclaim, duplicates and four-player cap |
| G06 | Native three-dot menu and in-game overlay | iPhone 17 simulator / iOS 26.5 | passed visual smoke | Native UIMenu with Game/Controls/Data/Info submenus and the Xbox overlay render; evidence `evidence/ios-shell/menu-controls.png`, `touch-overlay.png` |
| G06 | App-owned pad bridge into the engine | iPhoneOS 26.5 | passed for link | Host pad override and rumble callbacks exported; device input behavior still unverified |
| G06 | Contextual control help from game definitions | iPhone 17 simulator / iOS 26.5 | passed visual smoke | Controls menu opens a native reference using the engine's on-foot mapping and the drivecfg.def/POV pairings (RT gas, LT brake, B handbrake, A/X/Y secondary actions); evidence `evidence/ios-shell/control-help.png` |
| G06 | Driving and mounted-view help are distinct | iPhone 17 simulator / iOS 26.5 | passed visual smoke | The help page has separate Driving and Mounted views cards; the mounted card names POV variants (camera spin Y or B, reload A or X, secondary cycling by mount). Accessibility tree confirms all rows |
| G06 | Versioned app settings and persistence | macOS arm64 / iPhone 17 simulator | passed | `scripts/test_settings.sh` covers defaults, round trip, donor-key rejection, bad versions and values; toggling rumble in the shell wrote settings.txt and the relaunched menu showed Rumble off |
| G06 | Foreground controller reconciliation | iPhoneOS 26.5 build | implemented, unverified on hardware | On becoming active the shell re-enumerates controllers and releases stale ports; backgrounding stops rumble and neutralises every port |
| G06 | Only player one's controller hides touch controls | macOS arm64 / iPhone simulator | passed for policy | `scripts/test_touch_policy.sh` proves a port-one owner can hide, a port-two controller cannot, and always-visible/auto-hide-off win; the simulator's virtual pad on port 0 still hides the overlay |
| G06 | Touch overlay respects larger text (R29) | iPhone 17 simulator / iOS 26.5 | passed visual smoke | At XXXL the overlay and editor labels scale with `UIFontMetrics` capped at 20-22 pt, the editor hint stays one line, and labels fit their controls; evidence `evidence/ios-shell/touch-overlay-xxl.png`, `touch-editor-xxl.png` |
| G06 | Control labels meet WCAG AA contrast (R29) | macOS arm64 / iPhone simulator | passed | `scripts/test_contrast.sh` checks every control colour against white at 4.5:1 or better; the darkened palette still reads as the Xbox face colours |
| G06 | Overlay and editor reading order (R29) | iPhone 17 simulator / iOS 26.5 | passed visual smoke | Both accessibility trees follow movement, shoulders, system, look, then face buttons, with menu/Reset last; previously they were reverse subview order |
| G07 | Campaign inventory from the front-end text | macOS arm64 | partial | `DumpFiles=on` now works in the standalone build; a boot dumps `UKTxt.Dat`, which yields 18 campaign entries and nine multiplayer map names. See `docs/CAMPAIGN-INVENTORY.md` |
| G07 | Mission media coverage | Host | partial | The 30 fps bundle holds sixteen XMV files matching the seven action missions' intro and outro ids plus two menu loops; driving intros/outros live inside their mission VIVs and one has played in the handoff gate |
| G07 | Missing sub-level intro is tolerated | macOS arm64 | passed in a recording | The CastleExterior recording requests CastleCourtyard's missing intro, logs "cannot open" and still matches every frame; NightPad writes `Region=NTSC` to match the supplied 30 fps bundle |
| G07 | Difficulty and failure structure | Host | inventoried | Operative/Agent/00 Agent map to modifiers 1-3; mission states cover failed, died, timed out, results and retry; per-level objective counts recorded in `docs/CAMPAIGN-INVENTORY.md`. Runs still needed |
| G08 | Multiplayer limits, modes, maps and mods inventoried | Host | partial | `docs/MULTIPLAYER-INVENTORY.md`: 4 players + 6 bots, 13 modes, 11 weapon sets, 10 maps, Enviro-Mods options. Matches not yet run |
| G08 | Map-specific rules and mode availability | Host | partial | Ravine disables bots and mini vehicles; all maps use standard drone tuning; no source mode-to-map gate. Play confirmation still required |
| G08 | Character and mode unlock matrix | Host | partial | 13 modes (7 default, 6 reward-gated), 29 characters (12 default, 17 reward-gated), Explosive Scenery gated; medals and codes share one reward mask. Runtime unlock checks remain |
| G08 | Match rules and scoring | Host | partial | Duration 1-10 then 5-minute steps to 60 or unlimited; points/lives 1-10 then 5-steps to 120; victories in Arena/Team Arena, points elsewhere. Runtime match checks remain |
| G10 | Cheat inventory and allowlist | Host | decision recorded | `docs/CHEATS-RESEARCH.md`: original debug checkboxes and their flags, recommended Immortal and All Weapons/Unlimited Ammo, integration and test plan. Not implemented |
| G10 | Immortality and unlimited-ammo assists | macOS arm64 / iPhone 17 simulator | passed for flags | `scripts/test_assists.sh`: engine reports 3 with both on and 0 after clearing, then joins. The shell persists the choices and shows them in an Assists submenu; all-weapons equip is not wired |
| G10 | All-weapons equip | Host | deferred | Direct `-level` boot in the standalone harness segfaults, so there is no scripted way to reach a live player; the prototype was removed rather than shipped unverified |
| G11 | Online feasibility | Host | decision complete | No networking layer, no system-link or online strings, and no host transport seam. Netplay deferred in `docs/DECISIONS/0011-netplay-deferral.md`; R23 not applicable |
| G09 | Display settings menu and persistence | iPhone 17 simulator / iOS 26.5 | passed | Display submenu with Original/2×/3×/4×, AA off/FXAA and 4:3/16:9; choosing 2× wrote `render_scale=2`; evidence `evidence/ios-shell/display-menu.png` |
| G09 | Engine settings file content | macOS arm64 | passed | `scripts/test_engine_settings.sh`: disc path, render size, AA and widescreen keys written in order with expected values |
| G09 | Engine honors the render target | macOS arm64 | passed for one size | A run with RenderWidth/Height 1280x960 logs `rendering the game's 640x480 at 1280x960`; AA off is accepted silently. Sustained device performance still unverified |
| G09 | Higher targets run on the host | macOS arm64 | passed for host | `scripts/test_render_cost.sh` plays Mission 1 at 640x480, 1280x960 and 1920x1440; all reach the host's ~50 fps cap with 339-348 draws. The host is not resolution-bound, so this does not predict device cost |
| G09 | Secret Unlocks mechanism inventoried (R19) | Host | partial | 52 codes in five families act on the codename being edited (mission bits, reward mask, upgrades); invalid codes change nothing; device test plan in `docs/CAMPAIGN-INVENTORY.md` |
| G09 | Vertical field of view choice | macOS arm64 / iPhone 17 simulator | passed for wiring | Display offers 60° (original), 70° and 80°; choosing 70° wrote `fov=70`. The engine clamps 30-120 and scopes ignore it. Visual validation at each value remains |
| G05 | Diagnostics include session history and display state (R25) | macOS arm64 / iPhone 17 simulator | passed | The report now carries render size, display options, assist state and the last 20 events; a simulator report shows them, and event paths and credentials are redacted |
| G05 | Diagnostic and performance builds are distinguished (R25) | iPhone 17 simulator / iOS 26.5 | passed | `scripts/test_release_diagnostics.sh` builds the Release lane, boots one simulator, and reads a report that says `build_configuration=performance/release`; the script boots and shuts down its own device |
| G05 | Native shell home, menu and data panel | iPhone simulator / iOS 26.5 | passed visual smoke | `NightPadShell` builds; screenshots show persistent menu, data status/import panel, pause/about/diagnostics entries |
| G05 | Shell device compilation | iPhoneOS 26.5 | passed | `scripts/build_ios_shell.sh device` builds arm64 app without signing |
| G05 | Combined engine archive links into shell | iPhoneOS 26.5 | passed for link | `scripts/check_ios_shell_link.sh`: arm64, action bridge plus driving start, no loose SDL/FFmpeg/SPIRV dylibs |
| G05 | Host-owned SDL poll loop | macOS arm64 / iPhoneOS 26.5 | passed for build; device runtime unverified | `HostWindow_Poll` bridge exported; shell uses a 60 Hz timer; macOS transition gate still passes |
| G05 | Engine Start/Stop under the shell | iPhone/iPad | unverified | Start prepares data, starts action engine and polls events; physical device run is unavailable |
| G05 | Native pause/input/audio gating | iPhone/iPad | partial | Engine pause/audio and shell App Pause are wired; device run remains |
| G05 | Cooperative engine pause boundary | macOS arm64 | passed | `scripts/test_action_pause.sh`: frames 0→2, hold 3→3, resume→33; audio pause path exercised; normal cycles/transition still pass |
| G05 | Native-UI input suspension | iPhoneOS/macOS | passed for build/boundary | Pad/keyboard reads answer neutral and pointer deltas drop while suspended; shell menu/pause uses it; device behavior pending |
| G05 | Local diagnostic report review | iPhone simulator / iPhoneOS build | passed for core/review | `scripts/test_diagnostics.sh`; redacts home/container paths and credentials; simulator shows review/share screen; no automatic upload |
| G05 | Diagnostic report share/export | iPhone simulator | passed for presentation | Share sheet shows Save to Files and Copy; generated file read back from Logs/NightPad; deliberate save click and device use remain |
| G05 | About and source notices | iPhone simulator / iPhoneOS build | passed for surface | Version, source/donor links, independence and game-data notices render; link opening and device use remain |

Only rows with explicit execution evidence are marked passed. Source inspection
does not satisfy runtime acceptance.

