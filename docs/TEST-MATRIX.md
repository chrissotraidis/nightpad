# Test matrix

| Gate | Scenario | Target | Status | Evidence |
| --- | --- | --- | --- | --- |
| G00 | Public source pins resolve exactly | Host | passed | `config/dependencies.lock.json` |
| G00 | Full Xcode and both Apple SDKs resolve | Host | passed | `config/toolchain.json` |
| G00 | Code signing and physical-device availability | Host | blocked | No identity or device visible |
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
| G04 | Stop requested during engine boot | iPhoneOS 26.5 build | implemented, unverified on hardware | The shell holds the stop until the active engine advances a frame (180 s fallback) because cleanup from a half-built engine crashed in testing; menu shows "Stopping After Load…" |
| G04 | Engine stop during boot joins cleanly | macOS arm64 | passed | `scripts/test_driving_early_stop.sh` at 2 s (frames 0) and 8 s (frames 3577), plus the action lifecycle at a 1 s stop: every thread joins and the process exits 0 |
| G04 | Ten repeated action sessions | macOS arm64 | passed | File slots close per session; device-scoped buffers are reused; every cycle joins; settle 248 MB |
| G04 | Load-time initializer ownership | macOS arm64 | passed for transition | Fmv and LaunchOptions deferred; remaining graphics initializer is compatible |
| G04 | Action to driving and return transitions | macOS arm64 | passed, 10 cycles | `scripts/test_engine_transition.sh`; iPhoneOS execution remains device-blocked |
| G05 | Separate app data, save, cache, launch and diagnostic paths | macOS arm64 | passed | `NightPadPaths` unit coverage; directory creation and layout asserted |
| G05 | Transactional prepared-data import | macOS arm64 | passed for core | `scripts/test_data_import.sh`: preflight, staging, validation, cancel, atomic activation, replacement and rollback retention |
| G05 | Shell prepared-data import and relaunch | iPhone simulator | passed with synthetic fixture | Real shell import path; active tree and identity survive relaunch; existing save unchanged; production Files picker still needs a retail package |
| G05 | Shell import of the real prepared game data | iPhone 17 simulator / iOS 26.5 | passed | 56-file, 1.9 GB prepared tree imported through validation/staging/activation to identity `data-a3c98ab965ac41e559ac`; relaunch reports ready; a re-import left `Saves/slot1.sav` byte-identical; evidence `evidence/ios-shell/data-ready-real.png` |
| G05 | Production Files picker presentation | iPhone 17 simulator / iOS 26.5 | partial | Import action opens the system folder picker; navigating and choosing the prepared folder is still manual because the picker's remote UI is not scriptable here |
| G05 | Game saves routed to the durable Saves directory | macOS arm64 / iPhoneOS build | passed for wiring | The launch state's relative `saves` folder is a symlink to the app's Saves directory; `scripts/test_saves_link.sh` proves write-through, idempotence and refusal to replace an existing real folder. A real in-game save is still needed |
| G06 | Four-port Xbox input mixer | macOS arm64 / iPhoneOS build | passed for core | `scripts/test_input.sh`: short taps, edges, dead zones, triggers, source merge, release-before-acquire and port isolation |
| G06 | Versioned touch-layout model | macOS arm64 / iPhoneOS build | passed for core | `scripts/test_touch_layout.sh`: phone/tablet defaults, safe-area/44-point clamp, overlap-free defaults, round trip, reset, unknown rows and bad versions |
| G06 | Touch-layout editor save/reset/relaunch | iPhone 17 simulator / iOS 26.5 | passed | `--open-touch-layout`; Save wrote `Controls/layout-phone.txt`, relaunch rendered the saved geometry, Reset restored defaults and Save persisted them; evidence `evidence/ios-shell/touch-layout-editor.png` |
| G06 | In-game touch overlay and controller UI | iPhone/iPad | unverified | Editor only; no gameplay overlay, controller authority or physical run yet |
| G06 | Touch samples to Xbox pad and simultaneous input | macOS arm64 / iPhoneOS build | passed for core | `scripts/test_touch_input.sh`: stick vectors, eight-way D-pad, analog trigger depth, shoulder/system bits, five simultaneous touches and newest-finger ownership |
| G06 | Controller slot reconciliation | macOS arm64 / iPhoneOS build | passed for core | `scripts/test_controller_slots.sh`: stable slots, free-slot reuse, sole-controller reclaim, duplicates and four-player cap |
| G06 | Native three-dot menu and in-game overlay | iPhone 17 simulator / iOS 26.5 | passed visual smoke | Native UIMenu with Game/Controls/Data/Info submenus and the Xbox overlay render; evidence `evidence/ios-shell/menu-controls.png`, `touch-overlay.png` |
| G06 | App-owned pad bridge into the engine | iPhoneOS 26.5 | passed for link | Host pad override and rumble callbacks exported; device input behavior still unverified |
| G06 | Contextual control help from game definitions | iPhone 17 simulator / iOS 26.5 | passed visual smoke | Controls menu opens a native reference using the engine's on-foot mapping and the drivecfg.def/POV pairings (RT gas, LT brake, B handbrake, A/X/Y secondary actions); evidence `evidence/ios-shell/control-help.png` |
| G06 | Versioned app settings and persistence | macOS arm64 / iPhone 17 simulator | passed | `scripts/test_settings.sh` covers defaults, round trip, donor-key rejection, bad versions and values; toggling rumble in the shell wrote settings.txt and the relaunched menu showed Rumble off |
| G06 | Foreground controller reconciliation | iPhoneOS 26.5 build | implemented, unverified on hardware | On becoming active the shell re-enumerates controllers and releases stale ports; backgrounding stops rumble and neutralises every port |
| G07 | Campaign inventory from the front-end text | macOS arm64 | partial | `DumpFiles=on` now works in the standalone build; a boot dumps `UKTxt.Dat`, which yields 18 campaign entries and nine multiplayer map names. See `docs/CAMPAIGN-INVENTORY.md` |
| G07 | Mission media coverage | Host | partial | The 30 fps bundle holds sixteen XMV files matching the seven action missions' intro and outro ids plus two menu loops; driving intros/outros live inside their mission VIVs and one has played in the handoff gate |
| G08 | Multiplayer limits, modes, maps and mods inventoried | Host | partial | `docs/MULTIPLAYER-INVENTORY.md`: 4 players + 6 bots, 13 modes, 11 weapon sets, 10 maps, Enviro-Mods options. Matches not yet run |
| G10 | Cheat inventory and allowlist | Host | decision recorded | `docs/CHEATS-RESEARCH.md`: original debug checkboxes and their flags, recommended Immortal and All Weapons/Unlimited Ammo, integration and test plan. Not implemented |
| G10 | Immortality and unlimited-ammo assists | macOS arm64 / iPhone 17 simulator | passed for flags | `scripts/test_assists.sh`: engine reports 3 with both on and 0 after clearing, then joins. The shell persists the choices and shows them in an Assists submenu; all-weapons equip is not wired |
| G10 | All-weapons equip | Host | deferred | Direct `-level` boot in the standalone harness segfaults, so there is no scripted way to reach a live player; the prototype was removed rather than shipped unverified |
| G11 | Online feasibility | Host | decision complete | No networking layer, no system-link or online strings, and no host transport seam. Netplay deferred in `docs/DECISIONS/0011-netplay-deferral.md`; R23 not applicable |
| G09 | Display settings menu and persistence | iPhone 17 simulator / iOS 26.5 | passed | Display submenu with Original/2×/3×/4×, AA off/FXAA and 4:3/16:9; choosing 2× wrote `render_scale=2`; evidence `evidence/ios-shell/display-menu.png` |
| G09 | Engine settings file content | macOS arm64 | passed | `scripts/test_engine_settings.sh`: disc path, render size, AA and widescreen keys written in order with expected values |
| G09 | Engine honors the render target | macOS arm64 | passed for one size | A run with RenderWidth/Height 1280x960 logs `rendering the game's 640x480 at 1280x960`; AA off is accepted silently. Sustained device performance still unverified |
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

