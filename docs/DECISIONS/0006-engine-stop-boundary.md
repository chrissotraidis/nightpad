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

The combined harness then starts the action engine from the page. It crashes
during the driving boot after shader 7 with the two isolated engines linked
together, while each engine passes alone. The fault is MEM_size called from
RCARPFile::LoadEAGLMaterials, not shader translation. The likely boundary is
that both engines' startup constructors run when the combined image loads,
before the coordinator selects an engine.

The load-time tables name the exact constructors. Action contributes Fmv.cpp,
LaunchOptions.cpp and sdlGpuBackend.cpp. Driving contributes sdlGpuBackend.cpp,
DirectorQueue.cpp, Gain.cpp, Decals.cpp, Materials.cpp, PostProcessing.cpp and
PlayMPC.cpp. The common graphics constructor running from both engine copies is
the first thing to defer or share.

Making the Fmv player and LaunchOptions text singletons allocate and construct
on first use removed two action load-time constructors. With that change, the
combined page-driven harness passes: driving boots and stops, requests
DEFAULT.XBE, closes and joins, then action starts from the page, closes and
joins. The remaining sdlGpuBackend constructors no longer prevent the
transition.

The harness also exercises the reverse direction through the game's
psiLaunchDriving seam. Action starts, reaches the configured frame, writes the
page, requests DRIVING.XBE, closes and joins. Both launch callbacks are observed
in sequence and both threads join.

A three-cycle soak passes cycle one and faults as cycle two enters the driving
engine's main. Engine static constructors are now guarded once per process, so
the remaining failure is mutable process-global engine state that has not been
reset between starts.

Keeping SDL initialized while recreating only the window improved action
repetition but caused the driving join to time out, so that experiment was
reverted. The accepted boundary remains: repeated action cycles pass, a single
bidirectional cycle passes, and a second driving start is not yet safe.

The reverse trigger now takes its page from the game's own Boot_GetPTPData
handover rather than a zero-filled buffer. The second driving start still faults
after entering main, so this is not a malformed-page problem.

## Repeated-launch reset contract

The second-start fault was not one global. The driving session's `Bond_CleanUp`
calls `UMemory::Shutdown`, but `ApplicationMemoryHeapConfig` was guarded by a
process-lifetime flag, so the next boot re-entered the game with the allocator
switched to its dead function table. The heap now comes back up for every
session. That exposed a chain of other process-static state whose nodes had been
freed with the old heap:

- file-system workers and slots (`FILESYS_shutdown`, before the heap goes away);
- file-name request lists and EAGL's loaded-object chain and symbol pools;
- the C++ stream locale, facets and standard-stream table;
- input action/update lookups, the Simulation's object maps, and every
  `URefCounter` tree;
- mix, voice, debug-audio, grid, target-picker, AI-vehicle and action-queue
  state;
- `PVehicle`'s car-name cache and the physics extension-type id.

Each reset is explicit and runs only after the new heap exists. Re-running the
whole constructor table is not a reset contract: `AIVehicle::Construct` and
similar constructors allocate, and repeating the table faults in
`UMemory::FastAlloc`. The resurrection call for AIVehicleController is narrowly
scoped to the static vehicle arrays.

Thread stacks were the other repeated-launch limit. They must stay in the 4 GB
game window because game data can hold stack addresses, but mapping each new
1 MB stack in the general window fragmented it enough for the third launch to
fail with `ENOMEM`. Stacks now come from the image's in-window arena, with a
smaller-reservation fallback. This is not a leak allowance: it gives each
session a valid in-window stack while the general window remains available for
game memory.

## Evidence and remaining gap

Three complete driving start/stop cycles pass, with each thread joined and the
OS thread count settling at nine. Three combined driving/action cycles pass,
including both directions through the real launch page, with joins and a stable
thread count. The three-cycle action-only soak also passes.

A ten-cycle action-only soak still fails after cycle six: resident memory grows
by about 105 MB per action session, mostly `IOAccelerator (graphics)` and
owned graphics mappings. Destroying the GPU device at the next start, destroying
it before the window goes away, reusing one device, waiting for GPU idle, and
reusing one window were each tried; none removed the growth, and the persistent
window also leaked threads. This is a Metal/SDL session-resource problem, not
the heap or game-static reset fixed here. It remains open for G04; the mixed
three-cycle transition is the current verified boundary.

