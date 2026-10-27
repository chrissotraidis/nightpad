# NightPad autonomous goal loop

**Version:** 1.0  
**Prepared:** 27 October 2026  
**State:** Dormant planning specification. Nothing in this packet has been executed.  
**Product contract:** [NIGHTPAD_PRD.md](NIGHTPAD_PRD.md)  
**Machine-readable plan:** [goal_plan.json](goal_plan.json)  
**Initial state:** [execution_state.template.json](execution_state.template.json)  
**Research inputs:** [SOURCES.md](SOURCES.md), [sources.lock.json](sources.lock.json)

## 1. Activation and mission

Activate this loop only when Chris instructs an implementation agent to build NightPad. Merely reviewing or saving this packet does not activate it. The current request is planning only.

Once activated, build the original Xbox 007: Nightfire as a native ARM64 iPhone/iPad app from `NightfireResearch/nightfire-cxbx`. Use the Xbox ISO in `ref/` or `REF/`; use Chris's pinned GalaxyPad and SunPad sources for the Apple interface and touch-control mechanisms. Keep advancing until the private-candidate completion gate passes or a concrete external/technical blocker remains after the unblocking procedure.

Do the work, including obtaining required public prerequisites, adapting code, building, diagnosing, testing and documenting. Do not repeatedly ask whether to continue at ordinary milestones. A failed compile, missing header, black screen, audio defect or broken transition is engineering work to investigate. It is not automatically a reason to return the task to Chris.

### Standing execution scope

After activation, the agent may:

- Create an isolated local NightPad workspace and local repository/branches when none exists, or use a worktree of an existing designated repository.
- Download public source dependencies and donor repositories at recorded revisions; build needed public tools; install ordinary prerequisites into task-local locations or through an existing authorized package manager.
- Implement the engine/app adapters, build/test scripts, diagnostic hooks and test fixtures needed for the PRD.
- Read, hash and extract the supplied image into ignored staging; use extracted data for local builds/tests; preserve the source image.
- Build private artifacts, use already available legitimate signing/device access, perform in-place test installs with save protection, and make local commits with meaningful evidence.
- Research specific blockers, use parallel reviewers on independent tasks, and update this plan when new evidence changes implementation details without changing the product scope.

This scope does not include purchases, new paid services, public publishing, App Store submission, external messages, deleting personal saves, replacing system toolchains, bypassing security controls, or changing the selected game/engine. Existing credentials may be used through their intended tools; do not expose, invent or request secrets in logs.

A missing Xcode license acceptance, device trust, signing identity or hardware connection is a real external dependency. Prepare the exact build and the smallest needed handoff, complete independent work, and report it precisely. Do not ask again for permissions already supplied by Chris. If a tool's automatic approval review blocks an action, name the rejected action and reason rather than disguising it as a technical error.

## 2. State, files and evidence

At activation, copy the template state into the implementation repository as `config/goal-state.json`. Keep this packet's original template unchanged. Set `execution_started_at`, the actual project root and execution environment; all test/requirement states begin unverified. Research findings are not completed implementation goals.

### Proposed future repository layout

| Path | Purpose |
| --- | --- |
| `apple/ios/`, `apple/shared/` | NightPad Apple shell, controls, lifecycle and settings |
| `vendor/nightfire/` | Pinned maintained engine checkout/fork with reviewable deltas |
| `references/galaxypad/`, `references/sunpad/` | Pinned read-only donor checkouts; not bundled runtime dependencies |
| `tools/extract-xiso/` | Pinned host extractor source |
| `ref/` or `REF/` | Owner-supplied original ISO and pre-existing reference data; preserve |
| `build/`, `generated/` | Ignored binaries, staged data, local manifests, private fixtures and evidence |
| `scripts/`, `tests/` | Reproducible build/test/data preparation and meaningful regression tests |
| `config/` | Dependency lock, product settings schema, goal plan/state without secrets |
| `docs/STATUS.md` | Current verified boundary, blockers, next ready goal |
| `docs/GOAL-JOURNAL.md` | Append-only iteration decisions and evidence references |
| `docs/DECISIONS/` | Architecture, feature adoption/deferral and supported-device decisions |
| `docs/TEST-MATRIX.md` | Requirement/scenario verdicts, target identities and missing evidence |
| `docs/UPSTREAM-DELTA.md` | Owning source, original pin, change purpose and regression evidence |

Paths are a design to create later, not files already present in a NightPad project. Preserve an existing project convention when it provides the same ownership and evidence. Keep source and donor checkouts separate from original retail data. Do not silently reset or clean a dirty donor or engine checkout.

### State vocabulary

Goal state: `pending`, `ready`, `in_progress`, `passed`, `blocked_external`, `blocked_technical`, or `reopened`.

Requirement state: `unverified`, `in_progress`, `passed`, `failed`, `blocked`, `decision_complete`, or `not_applicable`. Only Decision requirements may finish as `decision_complete`. Only R23 may be `not_applicable`, supported by the R22 netplay deferral decision. Core requirements cannot be skipped or waived by the agent.

A goal's dependencies are completion gates. While one is blocked, preparatory work on an independent aspect may continue with its output labeled partial; it does not pass the dependent goal. A regression reopens the lowest affected goal and invalidates downstream evidence that relied on it.

### Evidence record

Every accepted iteration records these fields in the journal or an indexed JSON record:

```json
{
  "goal": "G03",
  "requirements": ["R06"],
  "hypothesis": "A signed iPhoneOS build preserves the encoded-pointer invariants",
  "source_revision": null,
  "dependency_manifest_hash": null,
  "build_hash": null,
  "content_identity": null,
  "target": {"model": null, "os": null, "sdk": null},
  "scenario": "pointer-window probe",
  "settings": {},
  "commands": [],
  "expected": "Describe the pass condition before running",
  "observed": null,
  "verdict": "unverified",
  "evidence_paths": [],
  "limitations": [],
  "next_step": null
}
```

The null values are intentional. Fill them from actual execution; never treat the example as a test result. Keep image paths, game captures, device IDs and signing details in local private evidence, with only appropriate summaries in versioned docs.

## 3. The execution loop

Repeat this procedure until the authorized terminal condition is met.

1. **Recover state.** Read applicable repository instructions, the PRD, current status, latest journal entries, goal JSON, dependency lock and affected technical decision. Inspect git state and only the processes/devices owned by this task. Do not kill unrelated apps or shut down someone else's Simulator.
2. **Verify identity.** Confirm relevant source/dependency revisions, toolchain, content identity, settings, test profile and last-known-good artifact. Reuse a cache only when its full build identity matches; otherwise rebuild that layer.
3. **Select work.** Choose the lowest-risk-numbered unmet goal whose prerequisites allow useful progress, prioritizing G03/G04 platform feasibility. If blocked on an external input, choose the most valuable independent task and keep the blocker visible. Avoid optional enhancements while a core regression is unresolved.
4. **State one hypothesis.** Name the suspected cause or proposed behavior, smallest change, expected result, test and stop/review condition. A retry must change a relevant variable or use new evidence.
5. **Execute one bounded step.** Fetch required pinned sources/tools, make the smallest coherent change, or run the specific experiment. Parallelize independent source research and review, not concurrent mutations to the same files or performance measurements competing for the same device.
6. **Test correctness first.** Run the smallest meaningful test for the affected layer, then the nearest established gameplay boundary if behavior may change. Do not benchmark an incorrect build. Add a focused regression for substantial behavioral fixes where practical; avoid tests that merely grep for the implementation's own strings.
7. **Assess the result.** Keep when the stated gate passes; repair or revert your isolated experiment when it does not; record uncertainty when the test cannot answer the hypothesis. Never remove an assertion, turn off required rendering/audio, change test goldens or suppress a failure merely to advance.
8. **Record evidence and state.** Save exact commands, logs and identities; append the journal; update requirement/goal status and upstream deltas. Distinguish source, build, simulator, device-automated and hands-on evidence.
9. **Continue.** Select the next required step without asking for routine approval. Checkpoint before context loss or tool limits, including the exact next command and known-good build. Resume from that checkpoint rather than restarting research.

### Repetition and unblocking

Two identical failures with no changed evidence prohibit another identical retry. Investigate the first causal error, verify inputs/configuration, reproduce the previous working boundary, consult the pinned source, reduce to a small failing case, then test a different hypothesis. After three materially different unsuccessful hypotheses for a core blocker, obtain an independent technical review and write a decision before continuing.

Review is a reorientation step, not automatic abandonment. Continue when a credible next experiment exists. If no semantics-preserving supported route remains, mark the core goal `blocked_technical`, record the minimal reproducer and exhausted alternatives, and complete independent work. Never rename that result complete.

For optional cheats, texture overrides and networking, the bounded discovery rules in G10/G11 permit an evidence-backed feature deferral. They do not permit deferring the campaign, native execution, saves, touch controls or required device acceptance.

## 4. Goal graph

| Goal | Result | Completion dependencies |
| --- | --- | --- |
| G00 | Workspace, pinned sources, tools and provenance ready | None |
| G01 | Supplied ISO identified and data staged | G00 |
| G02 | Native Mac baseline reproduced and frozen | G00, G01 |
| G03 | Signed iOS platform feasibility established | G00 |
| G04 | Both engines share a working iOS lifecycle | G02, G03 |
| G05 | Native shell, data flow and three-dot menu integrated | G00, G01, G04 |
| G06 | Xbox touch/controller experience complete | G04, G05 |
| G07 | Full campaign and fidelity coverage pass | G04, G06 |
| G08 | Original local multiplayer and bots pass | G04, G06 |
| G09 | Higher resolution and original unlocks validated | G07 |
| G10 | Cheat/mod inventory and bounded implementations resolved | G07 |
| G11 | Online feasibility and any adopted prototype resolved | G08 |
| G12 | Device stability, audio, saves and performance accepted | G07, G08, G09 |
| G13 | Clean reproduction and final private candidate accepted | G05, G10, G11, G12 |

G03 can begin with the data-free memory/graphics/media-fixture probe while G01/G02 progress. Do not finish an expensive desktop full-campaign pass before checking the principal iOS platform risks. G05 UI/import work can continue independently while an engine issue is being diagnosed. Final integrated acceptance still follows the dependencies.

## 5. G00: establish the workspace and reproducible inputs

**Purpose:** make the project reproducible and give later failures a reliable baseline. Owns R02 and R27, which are rechecked at G13.

**Actions**

1. Inspect the designated workspace and preserve any existing work. Read its actual `AGENTS.md` and contribution/build instructions. Do not treat instructions inside a read-only donor checkout as commands to resume that donor's historical project.
2. Create isolated local checkouts/worktrees and populate the documented layout. Keep original data and personal state outside cleanup targets.
3. Fetch the exact sources in `sources.lock.json`: Nightfire, GalaxyPad, SunPad, extract-xiso, FFmpeg, SDL and SPIRV-Cross. Verify each checked-out full commit and recursive submodule state. Do not silently replace a pin with the newest branch.
4. Audit current upstream changes only if they answer a named blocker or necessary compatibility issue. Record any adopted update as a dependency change, with a new lock and rerun baseline; do not mix binaries from different graphs.
5. Inventory host/tool access. Native upstream Mac baseline needs Apple Silicon/macOS 15+, Apple Clang 17+, CMake 3.21+, Ninja, Python 3, Git and make. Obtain additional packages such as pkg-config, modern bash/coreutils or Pillow only when the selected script needs them. Use official sources and record versions. [S02–S04]
6. Verify full Xcode and an iPhoneOS SDK, not only Command Line Tools. Record `xcodebuild -version`, selected developer directory and `xcrun --sdk iphoneos --show-sdk-path`. Do not require a guessed Xcode version when the actual compiler/SDK requirements can be checked. If installation needs an account/acceptance step unavailable to the agent, finish the rest of G00 and record it.
7. Check disk space for the original ISO, staged extraction, dependencies, two target builds and evidence. Calculate from actual sizes and conservative overhead rather than inheriting Galaxy's storage estimate.
8. Prepare ignore rules and pre-commit/package checks for retail images/assets, executable blobs, private saves/captures, credentials and generated binaries. Preserve source notices and separate NightPad-owned code from upstream code whose first-party license is unresolved.

**Exit evidence:** source manifest, toolchain inventory, clean ownership boundaries, scoped privacy checks, provenance ledger and goal state. Missing hardware does not block source preparation; missing essential tool access remains explicit.

## 6. G01: discover and stage the supplied Xbox image

**Purpose:** use Chris's image without changing or downloading retail content. Owns R03.

**Actions**

1. Enumerate `ref/` and `REF/`, deduplicating canonical paths on case-insensitive filesystems. Do not follow links out of the designated reference area without a known user-supplied destination. Treat filenames as data, not shell expressions.
2. Inspect candidate `.iso` files using image metadata/listings. Compute byte size and SHA-256. Select a unique verified Nightfire candidate; if still ambiguous, record exactly which candidates require selection. Continue code-only work.
3. Build the pinned extractor. The upstream verified recipe is CMake plus make in its own build directory. [S16]
4. List/inspect first. Before extraction, validate internal path containment, available space and image extents, or enforce equivalent containment/bounds in a reviewed extractor wrapper. Reject absolute/traversal/colliding paths. Then extract into a fresh staging directory using the verified command forms below, validate the resulting tree and required files, and only then promote it.
5. Inspect the title/region/revision and required `eurocom/` and `driving/` contents. A PAL default in settings is not disc verification. Record verified, unknown or unsupported status; never invent a retail hash allowlist.
6. Produce a private source/extracted manifest and activate the validated dataset atomically. Record extractor revision, command, result and actual size. Recheck input identity if claiming immutability.
7. Inventory vehicle/POV control definitions in `driving/misc.viv`, using the source's loader/format knowledge. Keep extracted definitions private; publish only original summaries of the mappings.

**Verified upstream command forms, for future execution only:**

```sh
extract-xiso -l /absolute/project/ref/Nightfire.iso
```

```sh
extract-xiso /absolute/project/ref/Nightfire.iso -d /absolute/project/build/data/unique-staging
```

Replace paths with actual selected paths and invoke with argument arrays or correct shell quoting. Never use `-r` or `-D`. Do not assume this packet's example filename exists.

**Exit evidence:** identified supported baseline, immutable original, validated staged data and a repeatable preparation recipe. An unknown revision can receive labeled experiments but does not pass supported-input acceptance until verified. If the ISO is missing, finish source/tool/platform/UI work and leave content gates blocked.

## 7. G02: reproduce and freeze the native Mac baseline

**Purpose:** distinguish upstream behavior from NightPad regressions before introducing iOS changes.

Use **`macos-arm64`**. The preset named `macos` produces Windows cross-builds and is not the native Apple path. [S02]

### Verified native build recipe

These commands come from the audited upstream source/CI. They were not run during planning. Run them inside a clean pinned engine checkout, with one resolved absolute prefix used consistently:

```sh
git submodule update --init --depth 1 third_party/ffmpeg
```

```sh
sh tools/fmv/build_ffmpeg.sh macos-arm64 /absolute/project/build/deps/ffmpeg-macos-arm64
```

```sh
cmake --preset macos-arm64 -DNF_FFMPEG_LIB_DIR=/absolute/project/build/deps/ffmpeg-macos-arm64/lib
```

```sh
cmake --build --preset macos-arm64 --target driving_standalone driving_standalone_test action_standalone action_standalone_test gamewindow_test spirvmsl mslcompile
```

```sh
build/macos-arm64/gamewindow_test 200000
```

```sh
tools/fused_ops.sh build/macos-arm64/driving_standalone build/macos-arm64/driving_standalone_test build/macos-arm64/action_standalone build/macos-arm64/action_standalone_test
```

Inspect binary architecture/platform and dynamic dependencies. Confirm the floating-point audit's disassembler actually produced ARM64 instructions; an empty pipeline is not a pass. Preserve upstream numeric compiler policy and the explicit exceptions named by its audit. If a target path changes under a deliberate source update, obtain the actual target output from the generated build system and update the recipe.

### Gameplay/regression baseline

1. Set `DiscPath` to the validated data in isolated writable test directories, with separate profile/save state.
2. Run normal-speed windowed action and driving. Verify title/menu input, an on-foot slice, a driving slice, movies/audio and a real handoff. Record unresolved upstream defects honestly.
3. Discover the current action demo set. The initial pin has 12 files/221,759 frames. Produce a filename/hash/frame-count manifest rather than hard-coding a stale historical count. [S08]
4. Create a portable replay runner if needed. Upstream ships `tools/demo/play_demos.ps1`, not a ready `play_demos.sh`. Each run needs its own writable test directory and valid data path.
5. Require every complete recording's success status and expected end/frame count. Distinguish exit 0 from mismatch 2, input/sound ordering divergence 3, unreadable demo 4, process crash and timeout. The adapted verified hook form is:

```sh
NIGHTFIRE_DEMO_PLAY=/absolute/path/recording.nfdemo NIGHTFIRE_DEMO_FAST=4 /absolute/project/vendor/nightfire/build/macos-arm64/action_standalone_test
```

6. Establish local driving reference outputs using the documented runner. The author's private Windows runner is not available and is not a prerequisite. Initial verified local forms are:

```sh
RUNNER_HOST=local tools/runner/remote.sh setup
```

```sh
RUNNER_HOST=local RUNNER_SLOTS=1 tools/runner/round.sh new lockstep
```

7. Read local setup requirements before invoking it: disc/settings layout, FFmpeg location and image-comparison dependencies. Start with one slot. Do not claim historical reference images are bundled; create frozen same-machine controls and compare a second unchanged run before evaluating modifications.
8. Capture an actual shader corpus when needed and run `spirvmsl`/`mslcompile` against it. An empty folder is not shader coverage.

**Exit evidence:** both native executables and regression targets built, baseline gameplay slices observed, action/demo and driving results recorded with correct scope, reusable normal-speed test profile, and frozen build/data/config identities. A full Mac campaign is not required before G03; the full port campaign is G07.

## 8. G03: prove the signed iOS platform before full porting

**Purpose:** resolve address-window, linker, Metal and media risks early. Provides preliminary R06 evidence and prerequisites for R05/R08. R06 is not passed until G04 verifies real engine transitions/restarts, then rechecked at G12/G13.

No iOS preset or verified iOS build command exists upstream at the initial pin. Create those as NightPad work and document the commands only after they run. Do not label a proposed command as an existing upstream capability.

### Work packages

**A. Target/toolchain probe.** Build a minimal ordinary iPhoneOS app using the chosen Xcode SDK, ARM64 target and explicit deployment floor. Verify install/launch with available signing and an actual trusted device. Detach the debugger and relaunch. Keep the test data-free initially.

**B. Pointer/linker probe.** Port the existing game-window tests and static packed-pointer cases into that signed app. Inspect PIE/ASLR, `-no_fixup_chains` behavior, actual static/heap/thread-stack ranges and null/integer encoding. Exercise at least the upstream 200,000-operation workload and repeated cold launches. Record virtual reservations separately from resident memory. Any outside-window conversion must fail diagnostically, not truncate. [S05]

If the Mac arrangement is invalid, reduce to the actual conflict and evaluate a smaller suitable arena, runtime base/relocation, or explicit offset/handle adaptation. Preserve serialized 32-bit structures and prove each new conversion. Do not globally disable ASLR, widen binary layouts, introduce unsafe fixed mappings over existing memory, or request prohibited execution entitlements.

**C. Graphics probe.** Build pinned SDL for iOS and use its Metal GPU path. Change SPIRV-Cross platform selection appropriately. Render known shader/texture fixtures, readback and presentation with correct orientation. Exercise BC/DXT fallback where required and verify color/depth/alpha behavior. A mock simulator renderer does not pass this gate. [S06, S23]

**D. Media probe.** Add an iPhoneOS build of the pinned FFmpeg subset: XMV demuxing and WMV2, Xbox/WAV IMA ADPCM, EA MAD and EA R1 decoders as required by the engines. Inspect platform metadata of every library; preserve notices and choose a signed embedding/linking strategy. Verify a permitted local fixture, then real game media after G01. No Mac library reuse by renaming. [S04]

**Exit evidence:** signed physical phone and tablet platform probe results, supported address representation, working Metal/shader/media path, platform/SDK/deployment decision, no CPU JIT/debugger dependency. If only one form factor is available, record the other as blocked; continue independent code work without calling the overall device gate complete.

## 9. G04: integrate both engines into one lifecycle

**Purpose:** make the original campaign possible in a single signed app. Owns R05, R06 and R07.

1. Audit action/driving entry points, globals/static initialization, duplicated symbols, allocators, threads, I/O, audio callbacks and GPU ownership. Produce an ownership/reset table before merging them.
2. Build engine libraries with explicit entry points and isolated symbols. Keep platform services shared only where their contract permits it. Avoid broad renames that obscure upstream history.
3. Introduce an engine coordinator with observable states such as stopped, starting, running, paused, transitioning, stopping and failed. Define which thread may change state and which calls are legal in each state.
4. Intercept launch requests at `launchInfo.cpp`. Preserve the 0xC00-byte payload and mission/result semantics. Replace `fork`, `execl` and process termination with a coordinated transition after the current engine reaches a safe boundary. [S07]
5. Stop/join engine-owned threads, drain or cancel work under documented rules, quiesce audio callbacks/GPU use, close files, preserve durable state and only then reset/reuse memory.
6. Cover action→driving, driving→driving and driving→action, plus return to menu, death/retry and Stop Game→Start Game. Do not transplant Galaxy's next-launch engine-switch behavior.
7. Run ten repeated transitions for each supported direction using disposable profiles and valid checkpoint state, then a mixed sequence with interruption/background events. Compare launch payload interpretation, mission results, save progression, outstanding threads, resources and memory against baseline. Keep pointer-window assertions active and pass R06 only after integrated allocation/transition/restart invariants hold.
8. Investigate monotonic resource growth; demonstrate stable repeated-cycle behavior after caches warm. Do not set an arbitrary huge leak allowance to pass.

**Exit evidence:** both original engines run on physical devices in one app, transitions preserve state, repeated stop/reset is safe, no child process or forced whole-app exit required for normal campaign progression.

## 10. G05: adapt the native shell, data flow and menu

**Purpose:** make NightPad operable as Chris's product, with safe imports and real native pause. Owns R04, R15 and R25.

1. Read the pinned Galaxy donor files listed in the PRD. Extract menu/editor/window ownership/import mechanisms and retain their notices. Document every copied/adapted source and why it applies.
2. Implement an app path service separating imported data, profiles/saves, settings, caches, launch state and diagnostics. Remove executable/working-directory assumptions from the mobile path.
3. Implement the mandatory development data deployment plus a Files folder/prepared-package import transaction: permission scope, progress/cancel, storage preflight, validation, unique staging, atomic activation and rollback. Active game data changes only while the engine is stopped.
4. Present useful states: data missing, importing, invalid input, ready, launching, running and recoverable error. A canceled or failed reimport must leave previous data and saves intact.
5. Adapt `GalaxyPadNewEngineHost`'s overlay/scene approach to NightPad's SDL window. Retain the persistent three-dot affordance; strip Nintendo/game-engine-switch items.
6. Wire menu/editor/modal foreground state to coordinator pause, audio and neutral input. Original Xbox Start pause is separate. Reconcile dismissal at its beginning and avoid rebuilding an open menu.
7. Implement original NightPad branding, source/about links and local diagnostic viewing/export. Feedback export must let the player review what is being shared; no automatic messages/upload.
8. Test missing/invalid/canceled import, failed replacement, valid replacement, app relaunch, controls hidden, menu reopening, overlapping native modal states, and restoring the game to an appropriate original pause state.

**Exit evidence:** native shell and menu connected to a real engine session, working transactional data flow and diagnostics, menu always reachable, no stuck input or silent save removal. Shell-only Simulator tests are additional evidence, not integrated gameplay acceptance.

## 11. G06: finish the Xbox touch and controller experience

**Purpose:** adapt the donor controls to this Xbox game. Owns R12, R13, R14 and R29.

1. Implement one Xbox state adapter at `HostPadState`. Define per-port source ownership, stable player assignment, button-edge latching, analog ranges, neutral values, dead zones and release-before-reacquire policy. Galaxy's adapter is single-player; four ports require new ownership logic, not merely raising a constant.
2. Select SDL or GameController as the single physical controller authority. Preserve modern LB→White and RB→Black mappings, analog triggers and original Start/Back semantics. Remove the donor's View/Select native-pause shortcut. Audit rumble routing and clear it on pause/disconnect without affecting other ports.
3. Implement the actual default controls in PRD §7, including Y jump, A crouch and X reload/contextual interaction. Preserve the eight original game schemes and original inversion/aim/crouch preferences.
4. Use the imported Driving/POV definitions to finalize contextual layouts and help. Test all distinct active configuration families; do not infer vehicle actions from on-foot names.
5. Adapt Galaxy's touch editor and SunPad's second-stick/input mixing mechanisms. Author phone/tablet geometry with Xbox labels/colors and usable simultaneous aim/fire. Keep menu access independent of touch visibility.
6. Version NightPad layout/settings storage. Provide reset, save/relaunch persistence, bounds clamping and a path out of every editor state. Test extreme resizing, edge placement, landscape reversal and relaunch; Done/Reset/menu remain reachable and editing emits no gameplay input. Avoid importing stale Nintendo preference keys.
7. Add behavior tests for short taps across polling boundaries, simultaneous inputs, trigger ranges, cancellation, controller reassignments, connect/disconnect/background events and engine transitions. Test values at both sides of axis/trigger thresholds.
8. Perform physical phone/tablet touch sessions for move/look/fire/aim/jump/crouch/interact, menu navigation, night vision, weapon/gadget changes, scoped zoom and relevant vehicle controls. Exercise five simultaneous touches as a stress test, and separately prove a practical everyday grip during sustained move/look/fire and aim/reload/interact combat. Test interruption while buttons are held.
9. Perform physical controller sessions, including quick Start/Back taps, already-held buttons on connect, reconnect after sleep, touch auto-hide/manual show and multiple slot assignment. Joining controller P2 must not steal/clear/hide touch P1; only the touch player's own physical owner affects its auto-hide. Preserve unaffected player assignments and verify no input/rumble crosses ports.
10. Verify native accessibility labels, Dynamic Type where appropriate, focus/reading order, contrast and effective 44-point touch targets on small/large layouts. Do not claim the original 3D gameplay is screen-reader accessible because the shell is.

**Exit evidence:** usable Xbox controls on both form factors, original semantics and original menus retained, no duplicate controller input or stuck state, source/runtime/device evidence separated.

## 12. G07: prove the complete campaign and fidelity

**Purpose:** close the central product goal. Owns R01, R08 and R09.

1. Create a mission/section/mechanic inventory from source and supplied data. Include engine owner, start/end state, launch transitions, movies, saves, unique inputs and required success/failure routes.
2. Freeze a first-play route: original front end → fresh codename → action play → driving play → original progression → save → exit/relaunch/load. Do not choose debug shortcuts as the sole progression evidence.
3. Run all discovered action recordings at their embedded settings and the relevant driving scenarios against the frozen baseline. Track intentional portability deviations explicitly. Compare state and visual/media behavior separately.
4. Validate required shaders, texture cases, visibility/readbacks, scopes, cutscenes, HUD, fades and menus across the inventory. Investigate a black/incorrect effect rather than disabling it.
5. Complete a continuous campaign through the ending on the declared candidate, with no progression cheats. Use recorded input and level starts for diagnosis, then return to the real progression sequence.
6. Test mission failure/death/restart, original difficulty selection, alternate required mechanics and post-mission results. Verify final save and game-visible progress after a fresh launch.
7. Repeat the representative action/driving/transition/control routes on the second form factor. Maintain mission coverage evidence on the same source/config identity and explain where target-specific behavior was checked.

**Exit evidence:** complete campaign inventory covered, continuous ending/save/reload proof, no blocker in required mechanics or media. A title screenshot, replay-only pass or action-only build cannot close G07.

## 13. G08: preserve original local multiplayer

**Purpose:** make the chosen console experience work, not just the campaign. Owns R17.

1. Inventory every included map/mode and each distinct scoring/win-condition family, plus character/weapon/unlock dependencies. Preserve four human ports and six bot slots. [S12]
2. Smoke every available map/mode for load, start, gameplay and clean exit. Exercise each scoring/win-condition family; do not infer all modes work from Arena alone.
3. Complete Arena and at least one objective match with kills, respawns, pickups, scoring, bots, teams, result screen and another match.
4. Test one touch player with bots, two actual controllers, touch plus controllers and four logical ports at the six-bot limit. Use real four-controller evidence before claiming that physical configuration is supported.
5. Verify original horizontal/vertical two-player split and four-way layouts, independent controls, controller loss/reassignment, restart and return to the front end.
6. Test the original Player Mods and Enviro-Mods through representative effects and all menu options; these are preserved original features, not external mod support.

**Exit evidence:** inventory and match results, original limits/rules preserved, declared device/controller combinations tested, unsupported physical configurations explicitly listed.

## 14. G09: validate display enhancements and retail unlocks

**Purpose:** expose improvements that are already close to supported upstream behavior. Owns R18 and R19.

1. Establish original-resolution 4:3 rendering as the compatibility control. Keep committed replay runs at their embedded configuration, which can differ from the presentation baseline.
2. Expose measured higher render resolutions, correct 4:3/16:9 fit, AA Off/FXAA and validated vertical FOV. Record actual internal target size and final viewport, not only the selected menu value.
3. Apply size changes at the next game start unless a safe renderer recreation path is implemented and tested. Do not stretch to the phone ratio or expose unsupported AA values.
4. Compare action, driving, scope, HUD, cutscene, underwater/readback, menu and split-screen scenes at every advertised mode. Check simulation consequences where visibility changes. Preserve original simulation timing.
5. Select defaults from phone/tablet correctness and sustained performance. Higher resolution cannot be accepted through a short cool-device screenshot alone.
6. Exercise Secret Unlocks entry, original invalid-code/no-match behavior, toggle/set distinctions and codename save/relaunch persistence. An unmatched code must not succeed or mutate state; upstream's original behavior supplies no success message. Test broad unlocks idempotently; do not confuse character unlock names with debug effects. [S14]

**Exit evidence:** original baseline and at least one higher-resolution mode work at declared device settings; no aspect/scope/HUD/timing regression; original unlocks remain functional. MetalFX/dynamic resolution is optional and must not hold this goal open after its required scope passes.

## 15. G10: resolve cheats and Xbox-compatible modifications

**Purpose:** complete the requested enhancement research and implement justified features. Owns R20 and R21.

1. Build a concrete feature table: inherited retail option, original Secret Unlock, reconstructed debug handler, native convenience change, texture replacement or external content mod. Record platform, provenance, integration point and persistence scope.
2. Audit the actual debug-cheat activation paths. Prefer a small useful allowlist such as immortality and weapons/ammo if safe; test off/on/off, death/restart, load and engine transition. Do not imply action-only hooks apply to driving.
3. Keep new assists off by default, user-visible, reversible and absent from core acceptance runs. Avoid silently modifying progression. Network-related state must be synchronized or disallowed if G11 adopts netplay.
4. Search primary maintainer/source pages for original-Xbox-compatible modifications. Reject PC/Source platform mismatch, unavailable files or unverifiable compatibility rather than promising them.
5. For texture replacement, inspect the D3D9 hash/lookup/decoder contract and make one isolated SDL GPU/Metal proof using authorized or self-authored replacement content. Test missing/bad files, dimensions/mips, memory and fallback. [S13]
6. A positive feasibility result requires a recorded selected scope, completed implementation and device correctness/cost gates; it cannot be marked complete while the proven feature is left unimplemented. If the bounded prototype fails, allow two distinct technical approaches then review and record a concrete deferral: attempted designs, results, blocker and exact next experiment. Do not turn this into a new general mod engine.
7. If a modification is an Xbox binary patch, identify the intended behavior and reimplement it at an understood native seam with a test, or classify it as incompatible. Never write original x86 patch offsets into ARM64 memory.

**Exit evidence:** R20/R21 decision records, implemented-feature tests or specific justified deferrals, capability table in the app/docs that matches reality. An unexplored feature is not a completed decision.

## 16. G11: resolve online feasibility and any adopted prototype

**Purpose:** determine what online play can actually be added to this Xbox source. Owns R22 and, if adopted, R23.

### Discovery sequence

1. Read the timedemo limitations and map every simulation-affecting input. Include audio-device answers, renderer-visible objects, RNG, clock and file completion. Define meaningful state hashes and known exclusions. [S08]
2. Demonstrate matching state in two identical instances over a complete local bot match with matching views/settings and supplied input. Log hashes around pickups, kills, respawns and match end.
3. Deliberately change viewpoints/resolution/FOV and find the first divergence. Test whether shared simulation visibility can be computed independently of the locally presented view. Do not assume netcode follows automatically from input replay.
4. Choose input-delay lockstep only if the measured determinism and latency behavior support it. Otherwise evaluate host-authoritative replication at a concrete state boundary. Rollback is out of scope unless complete snapshot/restore and side effects are proven separately.
5. For each serious architecture, write one small prototype and at most one materially different follow-up approach to a blocking issue before independent review. Review should produce a supported implementation path or a precise deferral, not another open-ended research phase.

### If feasibility supports adoption

Implement a private two-device LAN/direct-address prototype with version/content/mod handshake, player allocation, input/state sequencing, timeouts, bounded buffers and disconnect policy. Use the same Xbox game data on independently running native clients. PC crossplay, remote video streaming and access to original Xbox online services are not this prototype.

Freeze the supported network profile and numeric latency budget before final acceptance. For each adopted profile, require at least one complete match and at least 15 minutes of play on two physical devices, with consistent authoritative scores/pickups/deaths, no undetected authoritative desynchronization, useful latency telemetry and correct match results. Test 30/60/100 ms RTT, jitter and 1% loss as proposed discovery conditions; explicitly report which profiles are supported versus rejected.

Exercise native menu behavior, background/foreground, peer loss, reconnect or clean session termination, incompatible version/data, invalid packets and safe return to offline play. A native menu blocks only local input unless a defined agreed pause protocol applies. No corrupt local profiles/saves or hung indefinite waits.

For Internet viability, document NAT/relay choices, security boundaries, service cost and operation. Do not purchase or publish infrastructure. A successful LAN prototype may close the adopted initial feature scope if Internet service is explicitly deferred and the product labels it LAN.

### If feasibility does not support adoption

Record the tested blocker, evidence, architectures attempted, reason to defer and next useful experiment. Mark R22 `decision_complete`, R23 `not_applicable` with that decision ID, and the feature `deferred`. Never describe that as working online multiplayer. The offline candidate can still complete its authorized scope.

**Exit evidence:** completed investigation plus either a tested adopted feature or an evidence-backed deferral. A networking wishlist or a copied PS2 UDP transport does not pass.

## 17. G12: accept physical stability, saves, audio and performance

**Purpose:** make the complete game reliable on both target form factors. Owns R10, R11, R16 and R24.

1. Freeze exact source/dependency/build/content/config identities for the candidate and create disposable test profiles. Protect any existing personal saves/settings before in-place updates; compare legitimate changes to expected gameplay rather than demanding every file remain byte-identical after play.
2. Exercise save creation, mission progress, codename changes, game-visible relaunch/load, backup/export/restore and failure during write. Use fault injection against test data to verify old-or-new valid state. Never destroy personal state for a test.
3. Exercise app foreground/background, interruption, native menu/editor/picker, audio route change, controller disconnect, memory warning, surface recreation, stop/start and process termination at defined safe/unsafe-save moments.
4. Hear and review music, voice, effects, movies and transitions at normal speed. Record underruns/queues/clocks, but do not substitute a nonzero PCM counter for an audio-quality verdict.
5. Freeze measurement routes and numeric budgets before optimization. Separate simulation speed from presentation FPS; target original cadence with 0.98–1.02 steady 10-second simulation/wall ratios. Record loading separately.
6. Run representative 15-minute action and 15-minute driving tests on the declared physical phone and tablet, including warm/thermally constrained conditions. Record frame times, missed deadlines, CPU/GPU work, peak/resident memory, thermal state, input latency and audio stability.
7. Compare baseline/candidate with one change at a time on the same route/settings/device. Exclude competing build/profile workloads. Keep instrumentation-light performance runs separate from heavy diagnostics. No disabled visibility/depth/audio or changed simulation cadence to manufacture speed.
8. Complete a 60-minute mixed campaign/multiplayer/menu/transition session and inspect leaks, stuck threads, crashes, saves and recovery. Rerun affected portions after any candidate-changing fix.
9. Produce actual hands-on touch/controller and audio verdicts. Use connected-device automation wherever it can answer the gate, but leave genuinely unavailable physical or human-perception checks blocked with a concise prepared session script.

**Exit evidence:** phone/tablet support matrix accepted, durable saves, working audio/lifecycle, measured stable performance, no unresolved required correctness or reliability defect. If hardware limits require a different supported-device floor, document the decision and do not claim success on the failed class.

## 18. G13: reproduce, audit and hand off the private candidate

**Purpose:** make the finished result concrete and repeatable. Owns R26, R28 and R30; rechecks every other requirement.

1. Build from a clean checkout with verified pins and a cold relevant dependency/build cache, using only documented public prerequisites and the owner-supplied data. No undeclared binary from a donor or prior experiment may be required.
2. Create and validate the local build/data/sign/install/package recipe. Adopt Chris's `padmint.json` convention after checking current schema support; add a supported schema extension only when needed and keep a working direct script path. Do not copy Wii input or recompilation stages into a source-port recipe.
3. Inspect the produced app's architecture, platform, embedded dependencies, signing/entitlements, data boundary, notices and file manifest. Private generated binaries remain private. A source/package audit must not mistake absence of a retail ISO for complete provenance clearance.
4. Run the current source checks, focused regressions, upstream applicable tests and candidate smoke/device matrix. Reuse earlier same-artifact evidence only when its identity and scope still match. Explain every excluded test and why it is irrelevant or externally blocked.
5. Perform independent skeptical review of the PRD checklist, campaign/multiplayer coverage, physics/graphics compromises, lifecycle/inputs, artifact identity and claims. Repair must-fix defects and retest only the affected risk plus required candidate gate.
6. Create the final private candidate and checksums; retain source/delta/dependency manifests, toolchain recipe, support matrix, feature dispositions, known issues and the exact known-good install/launch instructions.
7. Update `docs/STATUS.md`, journal and goal state. Set `complete_private_candidate` only when the terminal predicate below is true. Public source/binary publishing remains a separately requested action.

### Terminal predicate

- G00–G13 are passed on their documented scopes.
- Every Core requirement R01–R19 and R24–R30 is passed.
- R20–R22 are `decision_complete` with adopted-and-tested or explicitly deferred feature records.
- R23 is passed if networking was adopted, otherwise `not_applicable` with its R22 decision.
- Required physical phone/tablet gameplay, audio, touch/controller and performance evidence exists for the declared support matrix.
- The candidate hash and source/config identities match the acceptance evidence.
- No required gate is failed, blocked, unverified or silently waived.

If the predicate is false, finish with `blocked_external` or `blocked_technical`, an exact current working boundary and the smallest missing input/decision/test. Never present a partial build as the completed game.

## 19. Session reporting and recovery

During active work, give short updates at meaningful boundaries: what was established, the remaining uncertainty and the next experiment. Record detailed routine output in local evidence instead of flooding the user.

Before pausing for context/tool limits:

1. Preserve uncommitted work and evidence; create a local checkpoint commit if appropriate after private-data checks.
2. Record current goal, hypothesis, last command/result, exact artifacts and next step.
3. Stop only processes/profilers/test instances created by this task when needed to release files/device state. Leave unrelated applications alone.
4. Write an explicit resume instruction using the same files and pins. Do not repeat successful downloads, extraction or builds when verified caches remain valid.

For an external blocker, report: blocked goal/requirement, exact missing resource, evidence that it is needed, completed independent work, ready artifact/command and the smallest action Chris needs to perform. A bare request for permission to continue is not an acceptable handoff.

## 20. Final execution report format

The later implementing agent's report should lead with the actual outcome and include:

- Candidate location/hash, source revision, target devices/OS and whether it is ready for private play.
- Campaign and driving-transition result; touch/controller/menu behavior; save/audio/performance results.
- Higher-resolution modes, unlocks, adopted cheats/mods and exact online/LAN status.
- Verified source/dependency/build reproduction instructions and private input requirements.
- Known defects and unverified configurations, each tied to evidence and a next step.
- Every remaining external blocker, if any; no claims of publishing or testing that did not occur.

The loop ends when its authorized goal is achieved. It does not keep optimizing indefinitely, expand into another Nightfire edition, or publish by momentum.
