# Decision 0002: engine object isolation

Date: 2026-10-27

## Decision

Build each reconstructed engine as one relocatable Mach-O object, localize all
of its definitions with nmedit, and export one unprefixed coordinator
entrypoint per engine:

- NightPadActionEngineThread
- NightPadDrivingEngineThread

The engines retain their original global names internally. The coordinator
links both isolated objects into one signed app without changing serialized
layouts, renaming shared source, or giving either engine a dynamic process
boundary.

## Why

The two ordinary macOS standalone executables share 1,312 defined public
symbols. Even after separately partially linking each engine, 376 public names
still collide. These include rendering state, platform services, launch state,
C runtime support, audio and engine-specific functions with the same source
name. Merely changing a CMake target from executables to static libraries does
not provide an isolation boundary.

The partial link resolves each engine internally. nmedit then makes every
global symbol local except the single engine entrypoint. Local symbols may
repeat in separate objects, and both engines retain the addresses and layouts
their reconstructed code expects.

## Evidence

- Both complete iOS targets compile and link separately for iPhoneOS 26.5,
  arm64, deployment target 16.0.
- The action and driving iOS object sets (237 and 286 objects, excluding their
  standalone main) combine into isolated objects whose dynamic symbol tables
  contain exactly one engine entrypoint each.
- A combined iPhoneOS executable links both isolated objects with SDL3 and
  SPIRV-Cross. It is a Mach-O arm64 iOS executable and exports exactly the two
  coordinator entrypoints.
- The same test links and runs on macOS; a main that distinguishes the two
  function addresses exits successfully.
- `scripts/build_combined_engine_link.sh` reproduces the combined iOS link
  proof from the pinned engine build.

## Limits

This establishes link and symbol isolation, not lifecycle correctness. It does
not yet:

- stop and join every engine-owned thread;
- quiesce SDL audio and GPU callbacks;
- replace launchInfo's fork/exit boundary with a safe in-process transition;
- reset or release engine heaps and static caches;
- exercise action to driving, driving to driving, driving to action, or restart.

The link proof currently consumes SDL's shared iOS dylib. The product target
must use a signed static SDL or a correctly embedded framework before device
acceptance.

## Next experiment

Add a narrow bridge that registers a launch-request callback inside each
isolated engine, record the 3,072-byte page, stop the requesting engine at its
game-thread boundary, and start the other engine with a fresh window/GPU
session. Repeat each transition ten times with disposable profiles and keep
the pointer-window assertions active.

