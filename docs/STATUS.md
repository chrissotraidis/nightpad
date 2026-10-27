# NightPad status

Updated: 2026-10-27 11:40 UTC

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
- The combined driving-to-action harness crashes during driving boot after
  shader 7; both engines still pass their separate lifecycle harnesses.
- The image is Xbox title `0x45410026`, "007: Nightfire", version 1, region
  mask `0x7`, with only the `30_fps` movie bundle present.
- The driving/POV control definitions were safely decoded from `misc.viv`:
  eight POV configurations, one Driving configuration and a separate front-end
  map.

## Current uncertainty and blockers

- No valid Apple code-signing identity and no connected physical device were
  visible at inventory time. This blocks signed physical-device acceptance in
  G03, G06 and G12; independent build/UI work continues.
- The supplied image lacks the PAL `25_fps` bundle and the
  `073f0048.xmv` movie required by one recording. The alias is an explicitly
  labeled compatibility experiment, not a verified PAL replacement.
- Physical pointer, Metal, SDL and lifecycle behavior is unverified.
- G04's worker-thread shutdown, audio/GPU ownership transfer, reset contract and
  repeated in-process transitions remain to be implemented.

## Next step

Implement the engine start/stop coordinator and prove game-thread join plus
audio/GPU teardown before exercising recorded transition routes. The physical
device blocker remains separate and visible.

