# NightPad product requirements

**Version:** 1.0  
**Prepared:** 27 October 2026  
**Owner:** Chris Sotraidis  
**Status:** Research-backed specification. Implementation has not started.  
**Execution companion:** [NIGHTPAD_GOAL_LOOP.md](NIGHTPAD_GOAL_LOOP.md)  
**Evidence:** [SOURCES.md](SOURCES.md), [sources.lock.json](sources.lock.json)

## 1. Product decision

Build **NightPad**, a native ARM64 iPhone and iPad application that plays the **original Xbox version of 007: Nightfire**, using the reconstructed C++ in `NightfireResearch/nightfire-cxbx`. Adapt Chris's current GalaxyPad three-dot menu, Apple shell, and touch editor, with SunPad as a secondary dual-stick and input-mixing reference. The supplied Xbox ISO will be under the project's `ref/` or `REF/` directory.

The intended result is the complete game: on-foot missions, driving and on-rails sections, transitions, movies, audio, profiles and saves, original local multiplayer, and bots. A title screen, one level, or an action-only build is an intermediate milestone.

This packet authorizes no implementation by itself. The present task produces planning documents only. When Chris hands this packet to an implementation agent and asks it to execute, the goal loop supplies the standing instructions for autonomous local work, dependency acquisition, implementation, testing, recovery, and reporting.

### Product boundaries

- Use the selected Xbox reconstruction as the engine foundation. Preserve its original gameplay and document intentional changes.
- Compile the reconstructed source for ARM64. Do not substitute the PC GoldSrc game, a Source remake, the PS2 Rust project, an emulator, or an XBE static-recompilation project.
- Use ordinary iOS code signing and supported operating-system facilities. The acceptance build must work without a debugger attached, a CPU JIT entitlement, jailbreak, or downloaded executable modules.
- The ISO supplies the original game data. It is not a module that must be recompiled into ARM64 for this source port.
- Public release, App Store submission, paid network services, and messages to third parties are separate actions. The terminal execution goal is a tested private candidate and reproducible source/build handoff.

### What research establishes

At the audited source revision, upstream has standalone action and driving executables, a native Apple Silicon preset, SDL3 GPU/Metal support, higher-resolution rendering, and local split-screen with bots. The name `nightfire-cxbx` reflects its history; the current standalone path is substantially beyond a Cxbx injection experiment. Its reconstructed source is not a promise of 100% matching decompilation: documented portability and behavioral deviations remain. [S01, S02, S03, S09]

No ready-to-use Nightfire iOS target or public native iOS release was verified in this research. The plan is to extend an existing native source port, not to start decompiling the Xbox game from zero. Existing desktop reports are upstream evidence, not tests run for NightPad. [S01–S08]

## 2. Source baseline and reuse decisions

| Role | Repository | Initial audited revision | Decision |
| --- | --- | --- | --- |
| Game foundation | `NightfireResearch/nightfire-cxbx` | `8779cf79ff623b83b53b9acf9c0b0cd6639b75ab` | Freeze for first desktop and device baselines |
| Primary Apple UX donor | `chrissotraidis/galaxypad` | `4db10c4c11e35958aae8da23b4d80fe6e5fe88e3` | Reuse current overlay, host, menu, editor, import transaction, controller reconciliation |
| Secondary input donor | `chrissotraidis/sunpad` | `d40a0674afa7189c14bfd6ce6f099dd275b46397` | Reuse suitable dual-stick and input ownership mechanisms |
| Host ISO extraction | `XboxDev/extract-xiso` | `3f5b62cfe68f000b0e3c8a30104973f3a297948e` | Build the pinned extractor and use read-only list/extract operations |
| Movie/audio dependency | Upstream FFmpeg submodule | `8ae0b34901ba60a802f183ee75a250a9fc3e09a5` | Build the required codec subset for each Apple target |

These are research pins, not a claim that a NightPad dependency graph already builds. The future executor must verify and lock all nested sources, tool versions, build flags, and local changes. Upstream currently requests SDL `release-3.4.18` and SPIRV-Cross `vulkan-sdk-1.4.363.0`; their resolved full commits are recorded in `sources.lock.json` and must match actual checkouts before relying on a cache. [S02, S04]

GalaxyPad's current New engine and current overlay are the references. Its historical Old-engine PRD/goal log contains Wii and recompilation requirements that do not apply to NightPad. SunPad's loop structure is useful; its historical release pauses and Sunshine-specific rules are not NightPad instructions. [S17, S18, S22]

Project Reach was not accessible through the inspected public repository routes. It is an optional unavailable reference, not a prerequisite and not a claimed source of reviewed code.

### Exact donor inventory

All donor paths are relative to the pinned repositories. Preserve original notices and an attribution/delta ledger when adapting files.

| Capability | GalaxyPad source | Adaptation |
| --- | --- | --- |
| Three-dot menu and touch editor | `apple/ios/GalaxyPadGameOverlay.{h,mm}` | Retain UIKit menu/editor behavior; replace game-specific controls, labels, callbacks, defaults |
| Overlay above an SDL game window | `apple/ios/GalaxyPadNewEngineHost.{h,mm}` | Reuse scene/window ownership pattern; connect NightPad lifecycle and audio/input pause |
| Controllers and slots | `apple/ios/GalaxyPadControllers.{h,mm}`, `apple/shared/GalaxyPadControllerSlots.h` | Reuse single-player reconciliation concepts; implement new per-port Xbox ownership |
| Remapping UI and persistence | `GalaxyPadControllerMappingPrompt`, `GalaxyPadControllerMapping`, `GalaxyPadControllerMappingStore` | Replace Wii action tables with original Xbox state |
| Settings and sizing | `apple/shared/GalaxyPadSettings.{h,mm}`, `GalaxyPadControlSize.h` | Create NightPad keys and versioned layout data |
| Import/reimport | `GalaxyPadImportTransaction`, `GalaxyPadDocuments`, `GalaxyPadGameDataStatus`, `GalaxyPadImportActivation`, `GalaxyPadImportImagePolicy` | Reuse staging/activation/recovery; write Xbox validation |
| About, help, diagnostics | `GalaxyPadAboutViewController`, `GalaxyPadReportViewController`, `GalaxyPadDiagnostics` | Adapt product identity and source links; user-controlled local export |
| Second stick and short input edges | SunPad `apple/ios/SunPadGameOverlay.{h,mm}`, `apple/shared/SunPadInputMixer.{h,mm}`, `SunPadInputState.h` | Retain useful mechanisms; replace GameCube/FLUDD semantics |

The implementation should extract coherent mechanisms with their tests, not copy whole donor repositories into the application. Do not inherit Wii pointer, tilt, ride controls, Nintendo button masks, Dolphin, RT64, or a recompilation module pipeline. [S18–S21]

## 3. Experience and supported targets

### Main player journey

1. Install a personally built NightPad app.
2. Import the prepared data folder/package produced from the owner's ISO, or use a development deployment that stages the same validated data into the app container.
3. See a clear validation/progress/result screen. A failed import retains the last working data and saves.
4. Launch the original Xbox front end, create/select a codename, choose original settings, and play.
5. Use the persistent three-dot button for display, touch/controller settings, audio, data/saves, help, and stopping the game.
6. Save through the game's original progress system. Relaunch and load the same progress.

### Platform scope

Primary targets are physical iPhone and iPad in landscape, with Apple Silicon macOS retained as a development reference. Both landscape directions should remain usable. The app shell may respond sensibly to other orientations without promising portrait gameplay.

Use an A15-class iPhone and an M2-class iPad as **proposed initial performance reference classes**, subject to actual device availability. This is a planning target, not a claim about Chris's currently connected hardware or guaranteed minimum requirements. Record exact models, OS versions, SDK, and signing configuration. Select the supported OS floor after the signed platform probe; SDL's API minimum is not proof of game performance or compatibility. [S23]

Simulator is useful for shell, import, layout, state-machine, and input tests. Current SDL GPU documentation lists the iOS Simulator as unsupported. Simulator work therefore cannot satisfy the game-rendering or physical-play gates. A shell test double may be used if clearly identified and excluded from gameplay evidence. [S23]

## 4. Requirements and acceptance ownership

Every requirement below has an owner goal in [goal_plan.json](goal_plan.json). `Core` requires implemented behavior and passing evidence. `Decision` requires a completed investigation and explicit disposition; the feature is implemented when the feasibility gate supports it. `Conditional` applies only after the associated feature is adopted. A deferral cannot satisfy a Core requirement.

| ID | Class | Requirement and acceptance |
| --- | --- | --- |
| R01 | Core | Original Xbox foundation. Identify source/data edition and preserve required campaign and multiplayer systems; no substituted game or engine |
| R02 | Core | Reproducible sources. Full root/nested pins, toolchain versions, local deltas, and cache identity recorded |
| R03 | Core | Safe ISO intake from `ref/` or `REF/`. Identify image, preserve source hash, validate extraction, and record supported/unknown status honestly |
| R04 | Core | Transactional app data import/reimport with progress/cancel/error handling, atomic activation, and independent saves |
| R05 | Core | Native ARM64 action and driving code runs as an ordinary signed app without CPU JIT, debugger, or child-process dependency |
| R06 | Core | All encoded-pointer/window invariants pass on physical devices through allocations, transitions, and restarts |
| R07 | Core | In-process action→driving, driving→driving, driving→action, restart, and stop/start preserve state and release resources |
| R08 | Core | Metal renderer, required shaders/textures/readbacks, movies, and correctly proportioned presentation work on device |
| R09 | Core | Full campaign progression from fresh codename through ending, final save/relaunch, and required mission mechanics |
| R10 | Core | Audible music, speech, effects, movies, pause/resume, and interruptions remain synchronized and stable |
| R11 | Core | Saves and profiles survive relaunch, interrupted writes, reimport, and app updates; backup/restore/export are verified |
| R12 | Core | Usable editable Xbox touch layout, simultaneous inputs, short taps, safe areas, and independently authored phone/tablet defaults |
| R13 | Core | Original mappings and context behavior preserved, including eight control schemes and data-driven vehicle/POV bindings |
| R14 | Core | Physical controller ownership, original white/black button equivalents, analog channels, disconnect/reconnect, and neutralization |
| R15 | Core | GalaxyPad-derived three-dot menu and editor remain recoverable; native UI actually gates local gameplay and audio |
| R16 | Core | Background/foreground, interruption, memory warning, surface recreation, and app stop/restart preserve valid state |
| R17 | Core | Original local multiplayer/bots and built-in rule modifiers work; four human/six bot limits preserved and coverage recorded |
| R18 | Core | Original-resolution baseline plus at least one measured higher-resolution mode; correct 4:3/16:9 presentation, validated FOV and AA choices |
| R19 | Core | Original Secret Unlocks remain usable and retain documented save/toggle behavior |
| R20 | Decision | Audit reconstructed debug cheats; implement validated assisted-play options or record a specific evidence-backed deferral |
| R21 | Decision | Inventory Xbox-compatible external mods and prove or reject a bounded SDL/Metal texture-override prototype |
| R22 | Decision | Complete bounded online feasibility research/prototype sequence and document the chosen architecture or concrete deferral |
| R23 | Conditional | If netplay is adopted, two independent native devices pass version/content checks, gameplay consistency, impairments, and disconnect handling |
| R24 | Core | Physical phone/tablet performance, thermal behavior, memory, frame pacing, and input/audio latency meet recorded budgets |
| R25 | Core | Useful local diagnostics and evidence without automatic external upload; diagnostic builds distinguished from performance builds |
| R26 | Core | Clean-checkout source/dependency/data preparation, build, personal signing/install, and package recipe reproduce |
| R27 | Core | Source notices and provenance retained; upstream licensing uncertainty documented; private data excluded from commits/packages intended for sharing |
| R28 | Core | Upstream relevant regressions and NightPad behavior tests pass; test absence, stale fixtures, and external blockers are explicit |
| R29 | Core | Native shell accessibility labels, text sizing, contrast, safe touch targets, and input help are verified |
| R30 | Core | Exact final private candidate, evidence manifest, known issues, support matrix, and one unambiguous next-step handoff exist |

## 5. ISO, data, and persistence contract

### Host preparation

The future loop searches only the designated project reference roots `ref/` and `REF/`, deduplicating them where the filesystem treats case identically. It discovers regular ISO files by filesystem APIs rather than assuming one exact filename. It inspects likely Nightfire candidates, not arbitrary unrelated files.

Use the verified `extract-xiso` list and extract modes. The tool handles trimmed XISO and full original Xbox image layouts; a custom ISO reader is unnecessary for initial host preparation. Do not use its rewrite/delete options. [S16]

Before extraction, record the source image path locally, byte size and SHA-256. Inspect title/region/revision metadata where available, structural layout and required files. A hash newly computed by the agent proves identity only. It is not a known-good retail hash. Upstream has tested the PAL European disc and requires `eurocom/` and `driving/`, approximately 3.2 GB. No verified retail hash allowlist was found. Do not infer PAL from the filename or from an INI default. [S01, S15, S16]

Create a unique staging directory, preflight available disk space and extraction bounds, reject unsafe archive paths, validate the result, then atomically activate a content-addressed data directory. Preserve the original image. If two candidates remain ambiguous, record the exact selection dependency and continue independent work rather than selecting randomly. An unknown but structurally valid revision may receive a clearly labeled compatibility experiment; it may not silently become a supported PAL baseline.

### Development versus player import

The mandatory first development path is **host ISO → validated extracted data → app container**. Do not bundle the retail data into a source archive or public IPA. A prepared folder/package and manifest can be imported through Files, with security-scoped access retained while copying. Device-side ISO extraction is an optional convenience; it is not needed to prove the port and must not become an early blocker.

The standalone source currently relies on executable-relative `DiscPath` and working-directory files. Replace those assumptions with an explicit path service. The app bundle is read-only; imported data, profiles, settings, caches, launch state, and diagnostics have separate locations. [S15]

| Data class | Proposed application location | Behavior |
| --- | --- | --- |
| Validated retail data | `Library/Application Support/NightPad/GameData/<identity>/` | Immutable during play; exclude reproducible bulk data from backup where appropriate |
| Profiles and game saves | `Library/Application Support/NightPad/Saves/` | Durable; original format/semantics first; separate from data replacement |
| Configuration/layout | NightPad preferences plus versioned layout file | Atomic updates; reversible migration |
| Import staging | App-owned staging area | Activate only with runtime stopped; cancel cleans only its own transaction |
| Regenerable caches | `Library/Caches/NightPad/` | Rebuildable; never the sole copy of progress |
| User exports | `Documents/` through Files/share UI | Save backups and deliberate diagnostics exports; never silently shared |

These paths are proposed NightPad design, not existing upstream behavior. Validate original Xbox virtual filesystem semantics before mapping files into them. Save durability means a real in-game load succeeds after relaunch, not merely that a file exists. Interrupted writes must leave the old or new valid state, with a recoverable previous copy. Routine test installs update in place using isolated test profiles; never uninstall an existing personal build just to clear state.

## 6. Native architecture and the early feasibility gates

### Proposed ownership

| Layer | Responsibility |
| --- | --- |
| Native app shell | Scene/window lifecycle, import, settings, menu, accessibility, controller/touch presentation |
| Platform services | App paths, input snapshots, audio, Metal/SDL window, clock, backgrounding, diagnostics |
| Engine coordinator | Select active engine, initialize/run/stop/reset, transfer launch page, own thread/resource lifetime |
| Reconstructed action library | Original on-foot game, front end, profiles and local multiplayer |
| Reconstructed driving library | Driving/on-rails execution, vehicle input definitions, mission section transitions |

Both engines must be signed with the app. Static libraries/object libraries with isolated symbols and explicit lifecycle entry points are the preferred first design. Any alternative must prove symbol isolation, state reset, signing compatibility and data lifetime. Loading downloaded code or launching another process is not an alternative.

### Gate A: address model, linker, and memory

`Ptr32` retains 32-bit fields as offsets in a 4 GB virtual window. On macOS the base is `0x100000000`; game allocations, selected thread stacks and static addresses must satisfy that encoding. The Mac arrangement includes large zero-fill virtual reservations, which must not be confused with committed physical RAM. The action link uses `-no_fixup_chains` for packed pointers. None of this is proof that signed iOS PIE/ASLR and memory limits accept the same layout. [S05]

The first device experiment must report link/load behavior, actual address ranges, round-trip pointer tests, static/heap/stack placement, guard behavior, resident memory, and repeated launches. If the Mac layout fails, investigate an iOS-compatible arena/relocation or base-relative representation while preserving on-disk structure layouts and null/integer distinctions. Do not widen serialized fields blindly or truncate ordinary pointers to make assertions pass.

### Gate B: iOS Metal and required media

Keep upstream's NV2A shader translation → SPIR-V → SPIRV-Cross MSL → SDL GPU/Metal route. `shaderMsl.cpp` currently selects macOS, so iOS platform selection and shader compilation are explicit work. Preserve numeric safeguards and validate translated shaders and required readbacks on actual iOS hardware. The existing fallback for unsupported compressed textures must be exercised on the target devices. [S06]

Build SDL and FFmpeg for iPhoneOS with an explicit deployment target. Mac dylibs are not iOS dependencies. Retain the current minimal FFmpeg codec/demuxer subset initially; do not bypass movies or silence audio as a completion shortcut. Upstream's FFmpeg script has no iOS mode, so a new target-aware recipe is required. [S04]

### Gate C: both engines in one process

The desktop path writes a 3,072-byte launch page (`psiLaunch.bin`), starts the next executable using `fork`/`execl`, and exits while game threads may still exist. Driving can also relaunch itself between mission sections. iOS apps cannot spawn child processes, so simply renaming both `main()` functions is insufficient. [S07, S24]

Define explicit start, update/run, pause, stop, cleanup and reset contracts. Audit global symbols and static state; isolate engine-specific globals; classify shared services; stop and join threads; release audio/GPU resources; reset heaps only after consumers release them. Preserve the launch page and results semantics. Test all three transition directions, death/restart, repeated stop/start and backgrounding during transitions. Default to one active engine at a time.

These three gates run before an expensive UI/features pass. A small single-engine device proof is an intermediate result. Final acceptance still requires the whole campaign.

## 7. Xbox controls and the GalaxyPad-derived interface

### Input boundary

Feed one normalized snapshot into upstream's `HostPadState`/`HostInput_ReadPad` boundary. The existing state has a 16-bit button mask, 8-bit triggers, four signed 16-bit axes and a packet counter, with Y positive upward and ports 0–3. Keep touch, physical controllers and test inputs distinct until a documented ownership/mixing rule combines them. Choose **one** physical controller authority, SDL or an Apple GameController adapter; do not let both submit the same pad. [S10]

Preserve short button edges between game polls and held/repeat semantics. Clear touch and controller state on ownership changes, menu entry, interruption and engine transitions. Require release before a held button is accepted from a newly acquired controller. Mapping should feed Xbox controls; the game remains responsible for its selected original control scheme. [S10, S20, S21]

Galaxy's current controller adapter is single-player and its overlay hides controls for any physical pad. Multiport ownership is new NightPad work, not a constant change. Assign sources to explicit Xbox ports and keep unaffected assignments stable. A controller joining P2 must not steal, clear or hide touch P1. Auto-hide is specific to the touch player's own port; restore touch when that physical owner disconnects unless manually hidden. Test input and rumble isolation between ports. [S20]

### Verified default on-foot mapping

| Original Xbox input | Default Nightfire function | Touch treatment |
| --- | --- | --- |
| Left stick | Move/strafe | Primary movement stick |
| Right stick | Look/aim | Second stick; optional touch-look is a later measured alternative |
| LT | Manual aim/scope | Reachable aim trigger; preserve original hold/toggle preference |
| RT | Fire/use selected gadget | Reachable fire trigger |
| Y, yellow | Jump | Xbox Y glyph and optional Jump label |
| A, green | Crouch; menu select | Xbox A glyph; original crouch preference |
| X, blue | Reload and contextual interaction | Reload/Interact label without inventing a separate original use action |
| B, red | Next weapon; menu back | Xbox B glyph |
| White, host LB | Alternate fire | Distinct White/LB control |
| Black, host RB | Next gadget | Distinct Black/RB control |
| D-pad left/right | Previous/next weapon | Four independent directional inputs |
| D-pad up/down | Next/previous gadget; contextual scope zoom | D-pad plus accurate contextual help |
| Back | Night vision; menu cancel | Separate from the app menu |
| Start | Original pause | Separate from the app menu |

The particularly important defaults are **Y = jump** and **A = crouch**. X interaction shares the reload action and depends on game context, including fire state. The eight original schemes are Nightfire, Moonraker, Octopussy, Goldfinger, Dr No, Thunderball, GoldenEye and Classic Bond. Preserve them; if optional action labels would be wrong for another scheme, update the labels or show Xbox glyphs alone. [S10]

Physical Menu/Start and View/Select must feed Xbox Start and Back. Remove the donor's View/Select-to-native-pause shortcut; Back is required for Nightfire's vision/menu behavior. Any controller shortcut for NightPad's app menu needs a separate nonconflicting binding.

Driving and POV bindings are loaded from `driving/misc.viv`, including `data/Control/Master.def`, `FrontEnd.def` and referenced definitions. Inventory and validate those from the supplied data before finalizing car, submarine, turret and on-rails labels. Preserve analog trigger values where consumed. Do not assume RT remains fire in every vehicle mode. [S11]

### Touch layout requirements

- Author independent landscape phone and tablet default geometry. Preserve two sticks, D-pad, Xbox face buttons, LT/RT, White/Black and Start/Back, with a tested way to reach every required action.
- Retain GalaxyPad's translucent control style, drag/resize editor, group handling for the D-pad, opacity/size settings, normalized safe-area positions, reset confirmation and persistent Done path.
- Provide versioned NightPad layout persistence. Named profiles or independent per-mode profiles are new NightPad work; donor defaults alone do not establish such a system.
- Support simultaneous movement, looking, aiming and firing. Verify a five-touch sequence, short taps, press-slide-release, cancellation, and thumb crossing near the screen edge.
- Treat five touches as an input stress test, not the intended everyday grip. Prove sustained move/look/fire and practical aim/reload/interact access on a representative phone combat route; revise a layout that only works with an impractical grip.
- Keep common controls at least 44 points in effective touch size, with clear contrast and meaningful accessibility labels for native UI. Verify reachability on a small phone, not just a large canvas.
- Auto-hide touch controls when an actual physical gamepad owns the player, with manual override. The three-dot button remains reachable. Editing forces the relevant controls visible.
- Keep stick-click channels available in the state model where needed; do not add permanent clutter for unbound actions without checking the selected context.

After extreme resizing, edge placement, changing landscape direction and relaunching, required controls and the menu/Done/Reset paths must remain recoverable. Editing emits no gameplay input. Verify that default hit regions do not unintentionally overlap.

### Three-dot menu

Reuse the current GalaxyPad circular 44-point `ellipsis` button, native menu behavior and safe-area anchoring. Organize NightPad's menu as follows. [S18]

| Group | Items |
| --- | --- |
| Display | Render resolution, 4:3/16:9 presentation, validated FOV, AA Off/FXAA, optional diagnostics overlay |
| Controls | Touch visibility/editor/reset/size/opacity; controller mapping/help; inversion and supported input preferences |
| Audio | Master/game volume and supported audio options |
| Game Data & Saves | Data status, import/reimport, save export/restore, remove data with explicit save separation |
| Enhancements | Only validated cheats/mod options; omit or clearly explain unavailable features |
| Help & Feedback | Xbox controls, known issues, version/sources, view/export diagnostics |
| Stop Game | Safely stop current runtime and return to the NightPad shell |

Do not copy Galaxy's engine selector or Wii-specific settings. Preserve the regression fixes that avoid rebuilding an open context menu and reconcile dismissal at the start of its animation. [S18]

For offline play, opening the app menu, editor or modal must neutralize gameplay input and suspend game progression/audio appropriately. Closing it resumes only if the app is active, no other modal blocks play, and the original game pause does not independently require remaining paused. Never resurrect pre-menu held input. In any future online match, the menu blocks local input but does not silently freeze the other players' simulation; define network pause explicitly.

## 8. Original game coverage

The future executor creates a campaign inventory from the actual source/data: ordered missions and subsections, action/driving engine owner, entry/exit conditions, save points, movies, unique mechanics and required controls. Do not assume action replay coverage spans driving or every story branch.

Full campaign acceptance requires a fresh profile through the ending and a successful final save/relaunch, without progression cheats. Per-mission replays and debug level starts accelerate debugging, but do not substitute for the continuous progression pass. Cover infiltration, aiming/scopes, gadgets, interaction, stealth/combat, damage/death/restart, mission failures, vehicles, on-rails/POV sequences, section transitions and final results.

Preserve local multiplayer and the original rule options, including Player Mods and Enviro-Mods. Those are retail features, distinct from external mod packages. The source has four human slots and six bot slots. Test one touch player with bots, two physical controllers, touch plus additional controllers, and all four logical player ports with the six-bot limit. A claim that four physical controllers work requires actual four-controller evidence; otherwise that particular device configuration remains explicitly unverified. [S12, S25]

Arena and an objective mode must both complete matches with kills, respawns, pickups, scores, teams, restart and return to the front end. Verify horizontal/vertical two-player splits, four-way viewports, disconnect/rejoin policy and independent input. Preserve original map/mode availability and unlock behavior.

Inventory every included map and scenario. Smoke each map for load, navigation/rendering and exit, and each scenario for start, a relevant scoring event and its win/end condition. Group genuinely shared mechanics with explicit coverage notes; two representative matches do not establish that every original scenario works.

## 9. Display, upscaling, cheats and mods

### Required display improvements

Upstream's `RenderWidth` and `RenderHeight` already render the scene at a larger target. This is the first enhancement to expose and measure. It is different from scaling up an already rendered low-resolution image. Initial quality options should include original resolution and one or more supported increases, selected from real device budgets. [S06, S13]

The existing renderer reads dimensions at device creation and blits into the whole swapchain. A responsive phone viewport, safe-area-aware presentation, arbitrary aspect ratios and live resolution changes are new work. Begin with correctly fitted 4:3 and 16:9 content, without stretching. Label restart-required settings truthfully until a tested live-recreation path exists.

FOV is vertical, defaults to the original 60 degrees and clamps to 30–120 in upstream. Keep cinematic and scope behavior intact. SDL GPU currently supports AA Off/FXAA; do not expose SMAA merely because an enum exists. MetalFX or temporal reconstruction is optional later work, requiring its own availability, image-quality, memory and latency evidence. [S13]

Preserve the original region-specific simulation cadence. An `FPS` override can alter timing and is not a harmless presentation-only switch. Do not promise 60/120 Hz game behavior or accelerate simulation by changing display settings.

### Unlocks and assisted play

Preserve the original Secret Unlocks UI and codename saving. Examples in the researched Xbox table include `PASSPORT`, `PARTY` and `GAMEROOM`; many individual codes toggle bits. `ZERO G` is a spacesuit-character unlock, not a zero-gravity cheat. Any friendly unlock-all action must be idempotent and must not blindly repeat toggle codes. [S14]

Debug handlers for immortality, weapons/ammo, movement, HUD and AI controls exist in the action source. Their presence does not prove safe standalone or driving behavior. Audit a small allowlist, then test activation/deactivation, death, restart, load and engine transitions. Keep the core campaign validation free of these assists. Default new assists off, identify their scope, and avoid silent profile mutation. Do not expose engine freeze/debug movement merely to fill a menu. [S14]

### External mods and texture replacements

Produce an inventory with source URL, platform, release/commit, license/provenance, required files, integration method and test result. No maintained Xbox-compatible HD pack or broad custom-map catalogue was verified in this research. PC Gearcraft, GoldSrc, AMX and Source content are not Xbox-compatible by default.

Upstream D3D9 has hash-based DDS replacement code; the SDL GPU backend does not carry that replacement/dump system over. A bounded prototype may separate lookup/decoding from backend allocation and prove one authorized replacement on Metal. Test missing/malformed files, mips, memory limits, fallback and disable/reload behavior. Keep overrides separate from immutable original data. [S06, S13]

Original-Xbox binary trainer offsets cannot be applied blindly to native ARM64 code. Reimplement an understood effect through a named native seam with a regression test, or reject the mod as incompatible. No runtime executable download/plugin loader is required for this product.

## 10. Online multiplayer discovery

The inspected Xbox project has local multiplayer, not a verified network layer. It cannot simply join original PC Nightfire servers. A Source remake, PS2 port or remote-streamed split-screen session is not a substitute for independent native Xbox NightPad clients. [S01, S12]

Complete the following bounded discovery before promising online support:

1. Inventory simulation inputs: pad events, clocks, RNG, file timing, sound-device answers, rendering visibility and any other host-dependent state.
2. Run two instances with identical content, revision, seed, views/settings and inputs; compare meaningful simulation hashes through a complete bot match.
3. Deliberately vary viewpoints, resolution, aspect and FOV. Locate divergence and determine whether rendering can be decoupled or an equivalent deterministic visibility pass is viable.
4. Choose a design from evidence: input-delay lockstep if deterministic behavior and latency are acceptable, or host-authoritative replicated state if they are not. Rollback requires a separately proven complete snapshot/restore boundary; a codename save is not such a snapshot.
5. If feasible, implement a two-device LAN/direct-address prototype with content/version/mod handshake, ordered input or state delivery, bounded queues, timeouts and disconnect handling.
6. Test normal play, deaths, pickups, bots, scores and match end under measured RTT, jitter and loss. Proposed trials are 30/60/100 ms RTT with controlled jitter and 1% packet loss; record actual test conditions and outcomes.
7. Decide whether an Internet path is viable, including NAT/relay requirements and operating costs. Do not buy services or publish a public backend under this plan.

The timedemo infrastructure is useful but does not prove network determinism. Its documentation says AI/autoaim consult recently drawn objects and sound-device answers are replayed. Independent player viewpoints can therefore affect shared simulation. The existing recordings stop at driving transitions. [S08]

For each adopted network profile, two physical native clients must complete at least one full match and at least 15 minutes of gameplay with consistent authoritative state, no undetected authoritative desynchronization, and tested background/foreground, timeout and disconnect recovery. Freeze a measured input-latency and correction/stall budget before acceptance. A host-authoritative client may have different device-local presentation state; whole-process hash equality is not the acceptance predicate for that architecture.

Each unresolved architecture gets a concrete experiment, with at most two distinct approaches before an independent review and disposition. This bounds speculative networking work; it does not authorize skipping a clear, small repair. If feasibility is demonstrated, finish and test the selected prototype. Apply the same rule to feasible cheats and texture overrides: a positive feasibility result alone does not complete the feature work. If not feasible, deliver the measured blocker and keep the offline game complete. R22 requires this investigation; R23 becomes required when the netplay feature is adopted. A deferral is not an online feature claim.

## 11. Verification and evidence

### Upstream baseline

The pinned tree contains **12 action recordings**, totaling **221,759 frames**. Older portability prose mentions 13; use the actual pinned inventory. The recordings embed their settings and starting state, and reflect the reconstructed build plus documented deviations. Treat successful playback as behavioral regression evidence for covered routes, not proof of universal Xbox equivalence. [S08, S09]

Run every available action recording at its embedded configuration, plus the relevant driving deterministic scenarios, address-window tests and floating-point audit. Confirm tools really ran: non-empty disassembly, expected replay frame counts, explicit verdicts, correct exit status, and completed driving tick ranges. Never regenerate/rebase golden recordings to make a regression disappear. Intentional behavior changes require an explained comparison and new fixture provenance.

Fast replay audio answers are simulated from the recording; audible output requires a normal-speed test. Render settings affect replay behavior, so run fidelity and enhancement tests separately. Headless execution cannot establish touch usability, audio quality or visible correctness.

### Required acceptance matrix

| Area | Minimum meaningful evidence |
| --- | --- |
| Source/dependencies | Root and recursive pins, tool versions, build options, original attribution, local delta |
| Input data | Identified image and extraction manifest; required data validated; original unchanged |
| Native build | Mac baseline and signed iPhoneOS artifact; actual platform/architecture inspection |
| Device platform | Pointer-window test, Metal/shader/texture/media probe; debugger detached |
| Engine lifecycle | All three transition directions, repeated restart/stop/start, thread/resource accounting |
| First-play slice | New codename, original front end, playable action and driving, save/relaunch |
| Campaign | Continuous progression through ending, mission inventory coverage, final save/reload |
| Touch | Both form factors; simultaneous controls, short taps, mode changes, editor, hidden-controls recovery |
| Controllers | Real controller play, quick Start/Back edges, ownership, disconnect/reconnect, local slots |
| Native UI | Menu/editor/modal pause and resume, no stuck inputs, accessibility and small-screen layout |
| Media | Music/voice/effects/FMVs heard and reviewed; interruption and transition checks |
| Saves/import | Atomic-write fault tests, game-visible load, failed reimport rollback, backup/restore, update preservation |
| Local multiplayer | Arena/objective matches, bots, splits, independent players, rules, score/restart |
| Enhancements | Original versus increased resolution/FOV/AA; scope/HUD/readback checks; cheats/mod decisions |
| Network | R22 experiment report; R23 two native devices and impairment results if adopted |
| Sustained operation | Phone/tablet routes, thermal/memory/audio metrics, 60-minute mixed-session soak |
| Reproduction | Clean checkout/cache-miss build and documented data preparation/signing/install |

### Performance policy

Measure original simulation speed separately from displayed FPS. The initial acceptance objective is real-time original cadence, targeting a simulation/wall-clock ratio of 0.98–1.02 in steady 10-second windows during representative 15-minute action and 15-minute driving runs on each reference class. Record loading pauses separately instead of hiding them in averages.

Capture frame-time distributions, missed deadlines, CPU/GPU cost, resident/peak memory, audio underruns, input-to-response latency and thermal state. Establish numeric memory/frame-time budgets after the first correct device run; freeze them before optimization. A platform limit may require a documented supported-device decision, not a falsified pass or a slower game silently called full speed.

Higher resolution is accepted only when the same correctness and sustained-operation gates pass. Compare one change at a time on the same scene/settings/device. Separate instrumentation-heavy diagnostics from logging-light performance measurements. Stop optional optimization when the agreed target is met.

### Evidence ledger

For each claim record: requirement/goal ID, source and dependency revisions, build/config hash, content identity, device/OS/SDK, scenario, settings, commands, time range, expected and observed result, raw evidence location, reviewer, and limitations. Keep game-derived captures and private logs locally by default. Redact paths/device identifiers before deliberate sharing.

Use distinct verdicts for source-inspected, build-passed, simulator-passed, device-automated, and hands-on-passed. A missing device session leaves its gate blocked. The agent must not write a human-played verdict from telemetry or fabricate screenshots, test counts or performance numbers.

## 12. Packaging, provenance and autonomy

Follow the useful organization of Chris's repositories: `apple/ios`, `apple/shared`, `scripts`, `config`, `tests`, `docs`, current status/journal, pinned dependencies and notices. Maintain engine changes in a clearly tracked source fork/submodule or equivalent reviewable branch, and app changes in NightPad. Do not recreate opaque patch stacks or copy runtime binaries from unrelated Pad projects. [S17, S22]

Produce a PadMint-style source recipe after validating the current schema. Galaxy's stages are dependency → runtime/engine → app → package. NightPad's recipe should reflect its actual source-built engines and user-supplied data; it must not claim an existing NightPad schema ID, supported Xbox input type, or ready command before those exist. Include an ordinary scripted local build path if PadMint needs a schema extension. [S17]

The audited Nightfire repository has no root first-party license granting general reuse. Galaxy/Sun donor notices include GPL terms; FFmpeg and the other dependencies have their own notices and obligations. Preserve all provenance, document unresolved source/distribution questions, and do not attach a blanket new license to reconstructed upstream code. This uncertainty does not block private source investigation and the technical work described here; it keeps public distribution separate. [S04, S17, S18, S26]

Future execution may autonomously fetch public sources, build/install necessary ordinary development prerequisites, create isolated local worktrees/branches, implement changes, run tests and produce local commits/artifacts. Prefer local dependency installs and an already available package manager. Do not replace global toolchains, delete user data, bypass OS controls, create paid services, send messages or publish by momentum. If credentials, trusted-device access, unavailable hardware, an unusable image or required permission truly blocks a gate, finish independent work and leave a precise blocker report. The companion loop defines resumption and completion.

## 13. Completion and open decisions

NightPad is **complete for the authorized private-candidate scope** only when all Core requirements pass on the declared device/support matrix, R20–R22 have concrete dispositions, adopted Conditional requirements pass, and the final artifact matches the evidence. Missing physical acceptance, missing driving transitions or an incomplete campaign prevents a complete status.

The first execution session must resolve or explicitly track these decisions:

| Decision | Evidence needed | Default direction |
| --- | --- | --- |
| Actual ISO edition | Metadata/content inspection and compatibility evidence | Tested PAL baseline first |
| iOS pointer layout | Signed physical-device probe | Preserve current encoding if valid; narrow adaptation otherwise |
| Engine isolation/reset | Global/link/thread/resource audit and repeated transitions | Two compiled libraries, one active coordinator |
| Controller authority | Donor/SDL callback audit and edge tests | One source of physical pad state |
| OS/device floor | Dependency build and measured device routes | Record tested support, no speculative minimum |
| Live resolution changes | Safe renderer recreation test | Apply at next game start until proven |
| Texture/cheat feature set | Small prototypes and per-feature tests | Ship only validated reversible options |
| Networking architecture | Determinism/divergence and two-device experiment | Bounded LAN first; no promised PC crossplay |
| Public distribution | Provenance/licensing and separate owner instruction | Private candidate only |

No implementation, dependency install, build, ISO extraction, device deployment or gameplay test was performed to produce this PRD. Its purpose is to make those future actions specific, resumable and testable.
