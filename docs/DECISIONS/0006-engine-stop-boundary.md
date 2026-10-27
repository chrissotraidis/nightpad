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
- The symbolized isolated action object crashed in ShaderMsl_Translate while
  freeing a string. The same code and data pass when the action object is linked
  without nmedit localization. This is an allocator/interposition boundary:
  engine-local operator new/delete no longer matches allocations made by the
  external SPIRV-Cross and C++ runtime objects.

## Decision

Do not treat nmedit localization as complete lifecycle isolation. Share the
process allocator and support runtime explicitly, or give every participating
static library a matching allocator. Do not claim combined-runtime acceptance
until the symbolized path runs without that crash and all created threads are
gone after join.

## Next experiment

Extract GameWindow's operator new/delete and the common runtime support into one
shared owner used by both engines and SPIRV-Cross. Then rerun the real start,
stop, join test under symbol isolation and compare thread counts and heap
identities before, during, and after the cycle.

