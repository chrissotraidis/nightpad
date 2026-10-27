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

