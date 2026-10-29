# Decision 0001: iOS platform probe

Date: 2026-10-27

## Decision

Keep the existing 4 GB game-window representation with
`kGameWindowBase = 0x100000000` as the first iOS implementation. Do not
redesign serialized pointer fields or introduce a relocatable arena until a
physical device fails the pointer probe.

The iOS host layer uses the SDK's narrower `vm_allocate` and `vm_region_64`
interface. Apple omits `mach_vm.h` from the iOS SDK even though the arm64
address and size words remain 64-bit. The change is isolated in
`patches/0001-ios-host-vm-abi.patch` and leaves the macOS path unchanged.

## Evidence

The iPhone 17 simulator (iOS 26.5) ran the 200,000-operation
`gamewindow_test` workload with 200,029 checks and zero differences. The image
was at `0x1022d4a60`; the game window base remained `0x100000000`. The test
covered static and heap allocations, page placement, operator new and a game
thread stack.

A Metal compute fixture compiled MSL, dispatched 32 by 32 threads, wrote a
texture with a known pixel and read back a sentinel. It passed.

The pinned FFmpeg configuration built as static arm64 libraries for both
`iphoneos` and `iphonesimulator` with an iOS 16 deployment target. The
simulator app decoded one video packet and one AD-PCM Xbox audio packet from
the owner-supplied XMV media and passed.

The unsigned `iphoneos` app compiles and links as arm64. It is not runnable
on hardware until an ordinary signing identity and trusted device are made
available.

## Limitations

- Simulator success does not prove fixed mappings or resident-memory limits on
  a physical phone or tablet.
- The physical-device probe, detached relaunch, repeated launch, installation
  and device signing remain unverified.
- This fixture does not yet exercise SDL's iOS Metal backend, the game's
  translated NV2A shader corpus, compressed-texture fallback or real display
  presentation.
- The unsigned device build is compilation evidence only, not R05/R06
  acceptance.

## Next experiment

On one trusted phone and one iPad, install a signed probe, detach the debugger,
relaunch it twice, save the reported window/static/heap/thread ranges and
resident-memory readings, then run the SDL GPU and translated-shader fixtures.

