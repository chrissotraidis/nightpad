# NightPad sources and research notes

**Audit date:** 27 October 2026. Repository links below are pinned to the inspected revisions unless explicitly described as current official documentation. Source IDs in the PRD and loop refer to these entries.

## Evidence method

The research inspected public primary source, repository metadata/trees, build definitions, implementation files and maintainer documentation through GitHub, plus official SDL/Apple guidance and the original Xbox manual. Parallel reviews covered engine portability, Chris's donor interfaces, and enhancements/networking. No game was built, no ISO was accessed, and no UI or physical device was exercised for this packet.

Source existence is different from working behavior. Upstream gameplay reports are attributed as reports; NightPad implementation/testing is future work. Absence findings mean no verified public implementation was found in the inspected sources, not proof that no private effort exists anywhere.

## Important corrections retained in the plan

- Use macos-arm64 for native Mac code; macos is a Windows cross-build.
- Current action fixture inventory is 12 recordings/221,759 frames, despite older prose mentioning 13.
- Replay guarantees depend on recorded rendering settings and sound answers; they do not establish easy netcode or universally exact Xbox behavior.
- The original default Xbox scheme uses Y jump/A crouch, with reload/contextual interaction on X.
- Galaxy's donor controller layer is single-player. Stable multiport ownership and per-player touch visibility are new NightPad work.
- SDL GPU texture replacements, iPhoneOS FFmpeg, iOS shader platform selection and in-process engine transitions are not existing finished features.
- No known-good retail hash allowlist was verified; a newly computed hash identifies a file but does not prove its region.
- Project Reach was unavailable in the inspected public routes and was not reviewed.

## Primary sources

### S01. Current Xbox source-port status

Primary maintainer description: native reconstructed Xbox program, action/driving, local split-screen/bots, PAL-tested data and required folders. Statements about gameplay are upstream reports, not NightPad tests.

- [README](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/README.md)

### S02. Native build and target selection

The native Apple preset is macos-arm64; macos is a Windows cross-build. CMake/CI identify the native targets, address-window test and floating-point audit.

- [CMake presets](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/CMakePresets.json)
- [CMake targets](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/CMakeLists.txt)
- [Apple ARM64 toolchain](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/cmake/toolchain-macos-arm64.cmake)
- [CI](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/.github/workflows/ci.yml)
- [Fused-operations audit](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/tools/fused_ops.sh)

### S03. Standalone engine and Mac portability records

Useful reproduction and architecture records. Historical milestone claims are narrower than complete current-device acceptance; preserve their dates and limitations.

- [Developers guide](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/DEVELOPERS.md)
- [Action standalone](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/action-standalone.md)
- [Action portability](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/action-portable.md)
- [Driving standalone](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/driving/standalone.md)
- [Driving Mac](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/driving/macos.md)

### S04. Dependencies and media

FFmpeg source is an explicit gitlink. Its build script includes Mac ARM64, not iPhoneOS, and enumerates the minimal codecs. SDL/SPIRV-Cross tags were resolved through GitHub to full commits in sources.lock.json.

- [FFmpeg recipe](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/tools/fmv/build_ffmpeg.sh)
- [Submodule definition](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/.gitmodules)
- [Dependency declarations](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/CMakeLists.txt)
- [SDL resolved tag](https://api.github.com/repos/libsdl-org/SDL/git/ref/tags/release-3.4.18)
- [SPIRV-Cross resolved tag](https://api.github.com/repos/KhronosGroup/SPIRV-Cross/git/ref/tags/vulkan-sdk-1.4.363.0)

### S05. Pointer window and Apple linker constraints

Ptr32 encodes offsets within a 4 GB window; relevant statics/heaps/stacks must remain representable. Mac reservation size is virtual, not a direct resident-RAM claim. The packed-pointer linker workaround needs an iOS probe.

- [Ptr32](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/driving/platform/Ptr32.h)
- [Game window](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/driving/platform/GameWindow.cpp)
- [POSIX host](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/driving/platform/HostPosix.cpp)
- [Address-window test](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/driving/devtools/GameWindowTest.cpp)
- [Link options](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/CMakeLists.txt)

### S06. SDL GPU, shader translation and presentation

Existing Metal path substantially reduces the work. iOS platform selection is new work. Dimensions are selected at device creation; full-swapchain presentation is not proof of safe phone aspect handling. The SDL backend omits D3D9 texture replacement/dump support.

- [SDL GPU backend](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/common/gfx/sdlGpuBackend.cpp)
- [MSL translator](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/common/gfx/shaderMsl.cpp)
- [GPU design notes](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/driving/sdl-gpu.md)

### S07. Current engine handoff and entry points

The 0x300-word launch page survives between engines via a file; POSIX launches child executables and exits while threads may remain. All three transition directions require new in-process coordination on iOS.

- [Launch handoff](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/common/launchInfo.cpp)
- [Action entry point](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/action/standalone/StandaloneMain.cpp)
- [Driving entry point](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/driving/standalone/StandaloneMain.cpp)

### S08. Replay inventory, determinism and its limits

The current set is 12 recordings/221,759 frames. Replays hold their recorded settings/audio answers; rendering visibility influences AI and autoaim. The recording is reconstructed-build behavior, not universal proof of Xbox identity. Driving transitions end action recordings.

- [Current demo inventory](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/tests/demos/action/README.md)
- [Timedemo documentation](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/action-timedemo.md)
- [Existing PowerShell driver](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/tools/demo/play_demos.ps1)
- [Local driving runner](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/tools/runner/round.sh)

### S09. Faithfulness and documented deviations

These documents establish why matching reconstruction and portable behavior must be distinguished. Known deviations and portable math cannot be silently erased from product claims.

- [Core deviations](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/core-deviations.md)
- [Deterministic math](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/deterministic-maths.md)
- [Action portability](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/action-portable.md)

### S10. Original Xbox inputs and host seam

HostPadState exposes four ports with Xbox-style buttons/triggers/axes. psiInput implements eight schemes and the actual Nightfire defaults, including Y jump/A crouch and shared reload/interaction semantics.

- [Host input](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/driving/platform/HostInput.h)
- [SDL input mapping](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/driving/platform/HostInputSdl.cpp)
- [Action mappings](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/action/engine/psiInput.cpp)
- [Action input types](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/action/engine/psiInput.h)

### S11. Driving and POV control definitions

Retail misc.viv contains Master.def/FrontEnd.def and referenced bindings; source and docs distinguish one Driving and eight POV configuration families. Actual retail definitions were not available in this planning task.

- [Driving input documentation](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/driving/input.md)
- [Input configuration loader](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/driving/engine/InputConfig.cpp)

### S12. Local multiplayer limits and architecture

Source defines four human players plus six bots. Local split-screen and its rule/scoring behavior are the inherited foundation. No implemented Xbox network layer was verified in the inspected project.

- [Multiplayer limits](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/action/game/mp/MPLimits.h)
- [Multiplayer header](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/action/game/mp/multiplayer.h)
- [Player/weapon/multiplayer architecture](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/architecture/player-weapons-mp.md)

### S13. Resolution, FOV, AA and texture overrides

RenderWidth/Height provide increased scene resolution. FOV is vertical with original default and bounds. SDL AA differs from D3D9; existing DDS replacement machinery is not already a mobile feature.

- [Xbox settings](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/action/engine/XboxSettings.cpp)
- [FOV definitions](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/action/engine/viewFov.h)
- [SDL GPU implementation](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/common/gfx/sdlGpuBackend.cpp)
- [Texture replacement](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/common/gfx/textureReplace.cpp)

### S14. Original Secret Unlocks and debug cheats

Original codes modify codename state and require saving; some toggle rather than set. ZERO G unlocks a character. Debug handlers are separate and require individual validation before a NightPad menu exposes them.

- [Secret-code research](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/ui/secrets.md)
- [Secret-code implementation](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/action/ui/ui_secrets.cpp)
- [Debug cheat handlers](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/action/ui/ui_cheats.cpp)

### S15. Paths and proposed upstream installer

Current runtime paths need an app-container adaptation. The upstream install/import document is a proposal, not an existing mobile importer or verified PAL hash allowlist.

- [Xbox path translation](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/src/common/xboxPath.cpp)
- [Installer proposal](https://github.com/NightfireResearch/nightfire-cxbx/blob/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab/docs/install-and-update.md)

### S16. Established Xbox ISO extraction

XboxDev's extractor supports list/extract and probes original-Xbox disc partition layouts. Use its pinned source and nonmutating modes, with source immutability and bounded staging. Rewrite/delete modes are unnecessary.

- [Extractor README](https://github.com/XboxDev/extract-xiso/blob/3f5b62cfe68f000b0e3c8a30104973f3a297948e/README.md)
- [Extractor implementation](https://github.com/XboxDev/extract-xiso/blob/3f5b62cfe68f000b0e3c8a30104973f3a297948e/extract-xiso.c)

### S17. Chris's current GalaxyPad product conventions

Current source and instructions distinguish the New engine from historical Old-engine plans. Useful conventions include pinned dependencies, app ownership, source/build recipes and explicit evidence boundaries. Past Galaxy approvals are not NightPad permissions.

- [Galaxy instructions](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/AGENTS.md)
- [PadMint recipe](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/padmint.json)
- [Dependency lock](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/config/dependencies.lock.json)
- [Historical goal-loop warning](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/docs/GALAXYPAD-GOAL-LOOP.md)

### S18. Primary menu, editor and SDL-overlay donor

Current UIKit source provides the grouped menu, persistent ellipsis button, editable controls and pause/input gating in a scene containing an SDL window. It must be adapted, not assumed engine-neutral.

- [Overlay interface](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/ios/GalaxyPadGameOverlay.h)
- [Overlay implementation](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/ios/GalaxyPadGameOverlay.mm)
- [New engine host](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/ios/GalaxyPadNewEngineHost.mm)

### S19. Transactional import donor

The reusable value is staging/validation/activation/recovery and Files access. Xbox content identity and extraction remain NightPad work.

- [Import transaction](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/ios/GalaxyPadImportTransaction.mm)
- [Documents integration](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/ios/GalaxyPadDocuments.mm)
- [Import activation](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/shared/GalaxyPadImportActivation.h)
- [Image policy](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/shared/GalaxyPadImportImagePolicy.h)

### S20. Controller and settings donor limitations

Galaxy's slot helper explicitly has one player; controller ownership and global auto-hide cannot simply be copied into four-player Xbox behavior. Preserve useful reconciliation but build per-port ownership. Remove the donor's conflicting View/Select native-pause shortcut.

- [Controller slots](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/shared/GalaxyPadControllerSlots.h)
- [Controller implementation](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/ios/GalaxyPadControllers.mm)
- [Overlay auto-hide](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/ios/GalaxyPadGameOverlay.mm)
- [Settings](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/shared/GalaxyPadSettings.h)

### S21. Secondary dual-stick and input donor

SunPad's stick and input-mixing patterns are useful; its GameCube/FLUDD and recompilation semantics do not apply to Xbox Nightfire.

- [SunPad overlay](https://github.com/chrissotraidis/sunpad/blob/d40a0674afa7189c14bfd6ce6f099dd275b46397/apple/ios/SunPadGameOverlay.mm)
- [Input mixer](https://github.com/chrissotraidis/sunpad/blob/d40a0674afa7189c14bfd6ce6f099dd275b46397/apple/shared/SunPadInputMixer.mm)
- [Input state](https://github.com/chrissotraidis/sunpad/blob/d40a0674afa7189c14bfd6ce6f099dd275b46397/apple/shared/SunPadInputState.h)

### S22. Existing evidence-driven loop precedent

Borrow the status/baseline/small-change/correctness/performance/record/replan structure. Do not inherit historical Sunshine approval rules, timing targets, compiler requirements or release restrictions.

- [SunPad improvement plan](https://github.com/chrissotraidis/sunpad/blob/d40a0674afa7189c14bfd6ce6f099dd275b46397/docs/IMPROVEMENT-PLAN.md)

### S23. SDL's official GPU platform support

The current official documentation lists Metal on iOS/tvOS and explicitly excludes their Simulators. API availability is not a NightPad performance claim. Recheck on a future dependency update.

- [SDL3 GPU documentation](https://wiki.libsdl.org/SDL3/CategoryGPU)

### S24. Apple's child-process restriction

Apple Developer Technical Support explicitly distinguishes macOS from iOS and confirms iOS applications cannot spawn child processes. This supports the need to replace the current executable handoff.

- [Apple DTS thread](https://developer.apple.com/forums/thread/747499)

### S25. Original Xbox manual

EA's original manual, available as a mirrored scan/text, is a primary product document. It describes original multiplayer settings, bots, two-player split orientation and codename saving. The mirror's generic title is not the actual game title.

- [Original manual mirror](https://device.report/m/09e9e436d46d0d47f44731a872d6d8125a294c302e7c16db1fe0ad5c61301c3e)

### S26. Source provenance and distribution uncertainty

Repository metadata and tree inspection did not reveal a root first-party license for nightfire-cxbx. Third-party notices do not grant a blanket license to all reconstructed code. Source contains executable-derived material, so do not claim the complete repository is free of game-derived content. This records a distribution question, not a legal determination.

- [Audited engine tree](https://github.com/NightfireResearch/nightfire-cxbx/tree/8779cf79ff623b83b53b9acf9c0b0cd6639b75ab)
- [Repository metadata](https://api.github.com/repos/NightfireResearch/nightfire-cxbx)
- [Galaxy overlay notices](https://github.com/chrissotraidis/galaxypad/blob/4db10c4c11e35958aae8da23b4d80fe6e5fe88e3/apple/ios/GalaxyPadGameOverlay.h)

## Revision and claim policy for later execution

Use sources.lock.json for the initial pins. A later upstream update requires a recorded reason, new full source identities and relevant baseline retesting. Treat README summaries, historical engineering logs, current code and actual runtime evidence as different layers; resolve conflicts using the pinned implementation and reproducible experiments.

This bibliography is a planning aid, not copied upstream source or a license grant. Public distribution and source provenance remain explicit decisions. The private image, extracted data and any future gameplay evidence are not included in this packet.

