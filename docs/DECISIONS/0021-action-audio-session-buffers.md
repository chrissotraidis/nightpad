# Decision 0021: retire action sound buffers between native boots

Date: 2026-10-29

Each action boot creates one DirectSound object and 192 buffers. The SDL and
XAudio2 backends kept a process-wide 256-entry registry without retiring the
previous boot's buffers. A second boot exceeded it. New buffers were returned
to the game but omitted from the per-frame 3D pass and PcmCache_InUse. That
could leave spatial gains stale and allow the PCM cache to evict data still
bound to an untracked voice. This is more than a diagnostic tracking limit.

Patch 0035 retires the prior device's buffer set on the next DirectSoundCreate,
which is where this game's boot replaces its AudioSystem. It releases the old
source voices before dropping PCM bindings, frees the buffer objects and
resets creation-order indices. The process-wide output device and independent
movie streams are retained. This does not run on an ordinary level reset,
where the game reuses its 192 buffers. XAudio2 mirrors the policy but was not
built on this host.

The focused test uses the actual SDL backend, PCM cache, mixer and dummy audio
with test-owned ADPCM. Fifteen boots create 2,880 buffers and play the final
buffer of each boot. Before the fix there are 2,624 registry warnings, later
PCM bindings are untracked and old voices accumulate to fifteen. Afterward
all PCM ownership checks pass, only the current test voice remains, final
reset releases it, and no registry warning occurs. Replay interception is
disabled; no retail samples or app saves enter this test.

Fifteen real native action starts/stops also join with settled thread counts
of six or seven, and no registry overflow. Reported RSS rises from 222 MB on
the first cold cycle to 264 MB on the final cycle; this is lifecycle evidence,
not a physical memory/performance acceptance claim. The unchanged 635-frame
replay, quick gates, both iOS builds, 35-export combined link, 35-patch/83-file
reconstruction and unsigned Release package pass. Full post-fix native engine
verification also passes: lifecycle, boot, pause, assists, actual intro pause
and stop, early stop, three transition cycles, real handover and mixed round
trip. The mixed action return no longer reports registry overflow.

The simulator still has the previous f504a63 build and is held under native
UI. Mac lock prevents installing/controlling the new build; unlock was
requested. No simulator or physical audio acceptance is claimed for 0035.
The SDL backend still has no HRTF or I3DL2 reverb; this fix does not resolve
that fidelity gap. Native evidence is in `build/tests/action-audio-sessions/`.
