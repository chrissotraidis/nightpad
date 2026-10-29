# Decision 0019: pause movie voices and clocks with native UI

Date: 2026-10-28

Patch 0033 closes the blocking movie gap identified in decision 0018. Both
movie players now pause their own FmvAudio voice and clock. The SDL path
unbinds the movie stream while preserving queued samples; it does not pause
the shared device. Resume excludes paused wall and virtual time, including
silent playback and the clock after the audio drains. Close clears pause
state. The Windows implementation mirrors this policy but was not built here.

The action loop applies this alongside its existing SFX/stream hold. The
driving player polls pause and stop before presentation and during its
clock wait. Stop leaves a paused movie without resuming its voice first;
the surrounding game sound manager also stays paused during teardown.
A separate presented-movie counter distinguishes this from simulation frame
zero. The shell can stop an active blocking movie before simulation starts;
it requests stop before releasing native UI ownership. Runtime starts clear
old pause flags and reset frame counters before creating the new worker.

The audio regression uses the actual SDL implementation with dummy audio:
silent, virtual, pre-Start, queued and drained clocks, repeated pause,
cleanup/reopen and a second voice on the same device all pass. The native
driving regression requires actual decoded/presented frames, freezes them,
resumes and stops while paused, twice in one process. Its isolated launch
page uses the engine's clean handover seed with only videoMode set to NTSC.
The default PAL seed and a CLI -ntsc argument miss the supplied NTSC movie;
those failed attempts are retained, not counted as pause passes. This
fixture never enters the app's campaign saves.

Simulator evidence in `evidence/fmv-pause/simulator/` shows action movie clock
11.357621 -> 11.357622 seconds across the native hold. The Paris movie holds
at presented frame 77, resumes, then holds at 624 while simulation stays at
zero. Stop returns to the data-ready shell in 1.825 seconds while paused.
NPRUN remains byte-identical to its original before-mission profile.

Native action pause, both iOS build lanes, the 35-export combined link,
33-patch/80-file reconstruction, quick gates and unsigned Release packaging
pass. The unchanged CastleIndoors1 recording still matches all 635 frames.
The full eleven-recording pass is from patch 0032; no new full-corpus claim
is made for 0033. Hardware audio/interruptions and campaign completion remain
unverified. A same-process restart after stopping an action movie showed an
unexpected zero-score Results page; investigate that separately before
crediting fresh-boot or campaign/results behavior.
