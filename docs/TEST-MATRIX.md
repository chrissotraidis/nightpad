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
| G04 | Ten repeated action sessions | macOS arm64 | passed | File slots close per session; device-scoped buffers are reused; every cycle joins; settle 248 MB |
| G04 | Load-time initializer ownership | macOS arm64 | passed for transition | Fmv and LaunchOptions deferred; remaining graphics initializer is compatible |
| G04 | Action to driving and return transitions | macOS arm64 | passed, 10 cycles | `scripts/test_engine_transition.sh`; iPhoneOS execution remains device-blocked |
| G05 | Separate app data, save, cache, launch and diagnostic paths | macOS arm64 | passed | `NightPadPaths` unit coverage; directory creation and layout asserted |
| G05 | Transactional prepared-data import | macOS arm64 | passed for core | `scripts/test_data_import.sh`: preflight, staging, validation, cancel, atomic activation, replacement and rollback retention |
| G05 | Native shell home, menu and data panel | iPhone simulator / iOS 26.5 | passed visual smoke | `NightPadShell` builds; screenshots show persistent menu, data status/import panel, pause/about/diagnostics entries |
| G05 | Shell device compilation | iPhoneOS 26.5 | passed | `scripts/build_ios_shell.sh device` builds arm64 app without signing |
| G05 | Combined engine archive links into shell | iPhoneOS 26.5 | passed for link | `scripts/check_ios_shell_link.sh`: arm64, action bridge plus driving start, no loose SDL/FFmpeg/SPIRV dylibs |
| G05 | Engine host under shell and real pause gating | iPhone/iPad | unverified | Engine archive and host wrapper link, but Start Game is still gated and no SDL window/event loop is attached |

Only rows with explicit execution evidence are marked passed. Source inspection
does not satisfy runtime acceptance.

