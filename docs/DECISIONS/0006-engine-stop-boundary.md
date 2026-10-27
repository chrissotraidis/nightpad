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
- That run exposed a real defect: process thread count rose from 1 to 6 while
  running and remained 7 after join. Worker/audio/SDL shutdown is incomplete.
- The first symbolized object crashed in ShaderMsl_Translate while freeing a
  string. Moving GameWindow and HostPosix into one shared runtime object fixed
  that allocator/interposition boundary: SPIRV-Cross, the engine and libc++ now
  resolve the same operator new/delete and host heap.

## Decision

Keep GameWindow and HostPosix in one shared support object linked outside both
localized engines. Symbols that own allocator identity must not be localized
per engine. The symbolized action start/stop path now runs without the shader
crash, but lifecycle acceptance still fails while worker threads survive join.

## Next experiment

Identify the surviving threads by owning subsystem, add an explicit shutdown
for each audio/SDL/engine worker, and require the symbolized start/stop/join
test to return to its starting thread count.

