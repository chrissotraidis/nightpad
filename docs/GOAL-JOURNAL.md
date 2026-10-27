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

