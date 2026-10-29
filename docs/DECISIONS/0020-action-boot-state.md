# Decision 0020: reset loader phase and handover cache at each boot

Date: 2026-10-28

Stopping an action movie left ResetMap_State at AFTER_MOVIE. A subsequent
in-process boot reset the flow stack and GameState but retained that loader
phase. Its new front end then traversed the old movie-completion path and
opened a zero-score Results page. Patch 0034 starts the loader at START when
GameFlow_ResetForBoot runs. A simulator Exchange movie Stop/Start now reaches
the original Press START title in the same process.

The same boot reset also invalidates XboxSystem's launch-page cache. Its
LaunchInfoUnread/HaveLaunchData statics otherwise retain the first boot's
answer, including an absent page, across later real engine handovers. The
cache remains stable within a boot and is refreshed only at the next boot;
no page contents or original Boot_LoadPTPData semantics are changed.

The regression links actual private engine functions from the native raw
object without adding app exports. Before the fix it fails four interrupted
loader phases and four new/replaced handover cases. After the fix it passes
initial absence, interrupted phases, absent-to-present, stable per-boot page,
replacement, direct-level bypass and deleted-page cases. All files are test
owned; this is not campaign completion evidence.

Both native action targets rebuild, the unchanged CastleIndoors1 recording
matches all 635 frames, and the native action -> driving -> action round trip
joins all phases. Quick gates, both iOS build lanes, the 35-export combined
link and unsigned Release package pass. The 34 patches reproduce 81 files.
Simulator title evidence and logs are in `evidence/action-boot/simulator/`;
native/build evidence is in `build/tests/action-boot/`. The original Paris
failure -> Quit route also returns through a newly read 3072-byte page to the
action mission menu in the same simulator process. NPRUN stays byte-identical.
No completed mission or earned results save is credited.
