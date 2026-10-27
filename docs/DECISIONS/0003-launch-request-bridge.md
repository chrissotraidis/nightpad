# Decision 0003: in-process launch request bridge

Date: 2026-10-27

## Decision

Keep the standalone child-process path as the default, but add a per-engine
request hook after the 3,072-byte launch page is durably written. A coordinator
that accepts the request records the image and page and ends only the
requesting game thread. It does not fork, exec or terminate the application.

Each isolated engine exports one callback setter and one thread entrypoint. The
coordinator receives the engine identity, requested XBE name, page pointer and
exact byte count.

## Evidence

`tests/native/test_launch_bridge.cpp` calls the real
`XLaunchNewImageA` from a separate pthread. The hook receives
`DRIVING.XBE`, exactly 3,072 bytes and a page identical to the original.
The on-disk `psiLaunch.bin` is also identical, and the requesting pthread
exits without a child process while the test process continues. The test
prints PASS.

Both complete iPhoneOS engines still build, and the combined isolation link
now exports four symbols: two engine thread entries and two callback setters.
The macOS action replay smoke test still matches all 635 frames after rebuilding
the native engines.

## Limits

Ending the requesting game thread does not by itself stop every worker thread,
audio callback, GPU submission or engine heap. It also does not reset the old
engine's static state or guarantee SDL window ownership can be transferred.
Those remain the core G04 lifecycle work. No transition has yet been run from
recorded gameplay.

## Next experiment

Add an engine stop request that lets the main-thread event loop return, join the
game thread, stop the audio device and GPU backend, then start the target
engine with the saved page. Test ten action to driving, driving to driving and
driving to action cycles, including a launch request while backgrounded.

