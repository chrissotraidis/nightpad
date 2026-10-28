# Decision 0016: send display settings the engine actually reads

Date: 2026-10-28

The native aspect menu persisted its choice correctly, but generated
`Widescreen=on/off`. The action engine reads this key with `atoi`, and the
driving engine's nonvolatile-setting seam uses `strtol`. Both interpret `on`
as zero. The old string-only test expected `on` and missed the integration
failure.

NightPad now writes `Widescreen=1/0`. The settings test compiles the real
action `XboxSettings.cpp`, writes the app-generated file in an isolated
directory, then calls `GetVideoMode`, the FOV/FPS accessors and the disc-root
accessor. Separate processes cover initial 4:3 and 16:9 loads. Before the
change, 4:3 passed and 16:9 failed; both now pass.

There is a second lifetime boundary: the action engine's settings cache was
process-scoped. Changing the native menu and writing a new file could not
change its cached aspect, FOV or disc root on the next Start in the same app
process. Patch 0029 adds `Settings_Reload`. The action runtime invokes it
before reading launch options, initializing movies or resolving the disc
root, while the previous engine thread is stopped. Reloading clears the old
settings structure before applying defaults and reading the new file.

The test also replaces the file in the same process, reloads it, and checks
the opposite aspect mode, a different FOV and a different disc root. The
runtime logs its resolved aspect flag and FOV at session start so subsequent
device and simulator checks can distinguish a menu choice from engine state.

This does not finish R18. `PresentOnWindowThread` in the SDL GPU backend still
blits the back buffer across the whole swapchain. On a wide phone that
stretches the game's frame instead of preserving the selected 4:3 or 16:9
presentation. The next renderer change must fit the selected presentation
aspect inside the drawable, clear the surrounding bars, and keep touch
controls usable. Verify both engines, the menus/HUD/scope, a phone and tablet,
and repeated aspect changes without changing game/render-test goldens.
