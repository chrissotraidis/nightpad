# Decision 0006: engine stop and allocator boundary

Date: 2026-10-27

## Result

Both game loops now honor a cooperative stop at the next frame boundary. The
action loop runs its existing cleanupSystem path; the driving loop leaves its
simulation loop so its existing GameLoop_CleanUp and Bond_CleanUp paths run.
The host can request window quit, wait for the game thread, join it, and close
the window.

## Evidence

- The complete native action engine, linked without symbol localization, starts
  from the runtime wrapper, runs its front end, receives an external stop,
  returns from Game_Main, and reports a joined thread.
- The first run left seven threads. Instrumentation identifies them as the
  process main thread, Cocoa's NSEventThread and five cached libdispatch
  workers; no engine/sound thread remains visible.
- The first symbolized object crashed in ShaderMsl_Translate while freeing a
  string. Moving GameWindow and HostPosix into one shared runtime object fixed
  that allocator/interposition boundary: SPIRV-Cross, the engine and libc++ now
  resolve the same operator new/delete and host heap.

## Decision

Keep GameWindow and HostPosix in one shared support object linked outside both
localized engines. Symbols that own allocator identity must not be localized
per engine. The symbolized action start/stop path now runs without the shader
crash. Three complete start/window/stop/join/close cycles finish with the same
seven OS-owned threads before and after cycles two and three.

## Next experiment

Repeat the test across the driving engine and a real action-to-driving
transition. Keep recording thread identities after every cycle so an
engine-owned leak cannot hide inside the stable OS worker pool.

## Driving follow-up

The driving runtime starts Mission 1, renders and reaches its simulation loop.
A cooperative stop runs GameLoop_CleanUp and Bond_CleanUp. Its normal return
requests DEFAULT.XBE; the callback receives the 3,072-byte page and the game
thread ends. One cycle now passes with the window closed before joining; the
driving cleanup path needs the main-thread window shutdown to complete before
the game thread returns.

