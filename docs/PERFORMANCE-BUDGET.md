# Performance routes and budgets

Status: **proposed, to be frozen at the first device session**. Nothing here is
measured on hardware yet. The routes and numbers are recorded before
optimization so later changes are judged against a fixed target rather than a
moving one.

## Build and device state

- Use the Release/performance lane, not a diagnostics build.
- Fresh install with a disposable codename; no other workloads, charging or
  screen mirroring during a run.
- Fixed brightness, Low Power Mode off, Wi-Fi off unless a run needs it.
- Declare the exact phone and tablet model, iOS version, thermal state and
  ambient conditions for every run.

## Routes

1. **Action, 15 minutes.** One continuous action mission with normal movement,
   combat, menus and at least one interior/exterior transition. Record the
   mission and starting save.
2. **Driving, 15 minutes.** One continuous driving mission, including the intro
   and outro or a menu return. Record the mission.
3. **Mixed, 60 minutes.** Campaign, multiplayer against bots, menu and editor
   use, at least one action/driving transition, a save and a relaunch.
4. **Warm/constrained repeats** of routes 1 and 2 after the device has already
   run for 20 minutes, without artificial cooling.

Loading is reported separately and is not part of the steady-state budget.

## Budgets

| Measure | Budget |
| --- | --- |
| Simulation cadence | 0.98-1.02 simulated time / wall time over a steady 10-second window |
| Presentation target | 60 fps; report misses above 16.7 ms rather than only the average |
| Frame-time tail | Under 2% of frames above 33 ms in a 15-minute route |
| Resident memory | No monotonic growth over 15 minutes; under 1.2 GB on phone, 2.0 GB on tablet |
| Thermal | Nominal or fair at the end of a 15-minute route at the default settings |
| Input latency | Touch or controller to visible response under 80 ms typical, under 120 ms at p95 |
| Audio | No audible dropouts; underrun and queue counters must match the audible verdict, not replace it |

The memory ceilings and thermal expectation are provisional until the first
measured session; if a device cannot meet them, record a supported-device floor
instead of claiming the failed class.

## What to record per run

- Route, mission, starting save, settings (render scale, AA, widescreen, FOV),
  build identity and device identity.
- Engine `PerfLog` lines: fps, working and waiting milliseconds, draw and
  pipeline counts.
- App diagnostics before and after: resident bytes, thread count, session events,
  and any recorded error.
- Thermal state at start and end, plus any visible stutter or audio artefact.
- For a change, the same route before and after on the same device and settings.

`scripts/summarize_perf.py <log> --label <route>` turns the engine's PerfLog
lines into JSON (mean/median/min/max fps, working and waiting milliseconds, and
the requested cap). Use `--skip N` to discard loading samples; it fails when a
log contains no samples, so an empty capture cannot pass as a measurement.

## What this does not cover

Host measurements from `scripts/test_render_cost.sh` are not device evidence;
the Mac is not resolution-bound and caps around 50 fps at every scale. The
simulator does not run the engine at all.
