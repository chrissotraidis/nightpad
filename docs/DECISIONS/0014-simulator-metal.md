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
to `d:\driving.xbe`, entered the Paris driving tutorial, and separately loaded
the campaign's Exchange mission into first-person gameplay. Holding the touch
left stick moved Bond and holding the right stick turned the camera. The
renderer reported SDL's Metal driver, MSL shaders and a 1280x960 back buffer.
See `evidence/ios-shell/simulator-title.png`,
`evidence/ios-shell/simulator-gameplay.png`, and
`evidence/ios-shell/simulator-exchange-gameplay.png`.

## Limits

- This is simulator evidence, not physical-device acceptance. Metal feature
  differences and performance still need a signed device run.
- A cold simulator launch compiles hundreds of pipelines. The game's own frame
  timestamps are not wall-clock time, so startup and mission-load budgets still
  need a separate measurement; the running driving session paced near 30 fps.
- The patch is pinned to SDL 3.4.18. Re-check it before changing the SDL pin.
