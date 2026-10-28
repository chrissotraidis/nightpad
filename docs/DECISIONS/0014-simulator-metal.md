# Decision 0014: the simulator uses SDL's Metal backend

Date: 2026-10-28

## Decision

NightPad's iPhone Simulator lane runs the real action and driving engines through
SDL_GPU's Metal backend. The pinned SDL 3.4.18 source rejects the simulator's
`MTLDevice` because it exposes the host GPU rather than an Apple GPU family.
`patches/sdl3-ios-simulator-metal.patch` relaxes that hardware-family check only
when `TARGET_OS_SIMULATOR` is true. `scripts/patch_ios_sdl.sh` applies it after
CMake fetches SDL, and `scripts/build_ios_engines.sh` invokes that script before
building either engine.

The device lane and its SDL archive are unchanged.

## Why

The simulator device supports the Metal operations the backend uses; its family
query does not match SDL's iOS hardware check. Keeping the workaround as a small,
idempotent patch against the pinned source is narrower than replacing SDL_GPU or
teaching the engine a second renderer.

## Evidence

On the iPhone 17 Pro simulator (iOS 26.5), the shell imported the real prepared
data, loaded all eleven `filesys` archives, started the action engine, handed off
to `d:\driving.xbe`, and entered the Paris tutorial with the touch overlay. The
renderer reported SDL's Metal driver, MSL shaders and a 1280x960 back buffer.
See `evidence/ios-shell/simulator-title.png` and
`evidence/ios-shell/simulator-gameplay.png`.

## Limits

- This is simulator evidence, not physical-device acceptance. Metal feature
  differences and performance still need a signed device run.
- A cold simulator launch compiles hundreds of pipelines. The observed first
  driving load took several minutes; the running game then paced near 30 fps in
  this simulator session.
- The patch is pinned to SDL 3.4.18. Re-check it before changing the SDL pin.
