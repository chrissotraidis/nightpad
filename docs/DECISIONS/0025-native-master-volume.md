# Decision 0025: native master volume

Date: 2026-10-29

The screenshot review in decision 0024 left the PRD Audio group unfinished.
The native root now includes Audio after Controls. Audio directly exposes a
Master Volume section with Muted, 25%, 50%, 75%, and 100% choices. A first
phone capture showed that seven root rows plus an app-name heading hid Stop;
removing that redundant heading keeps every root action visible at the
existing native row size. No smaller touch targets were introduced.

Patch 0038 applies attenuation to each engine's SDL logical audio device.
Game voices and the movie player's separate streams share that device, so
both are affected while original per-voice and movie levels remain intact.
Both isolated engine runtimes receive the setting, including the inactive
engine before a later handoff. Device creation and native changes share a
mutex; the audio callback never takes that mutex. Muting does not pause voices,
simulation, movie clocks, or file streaming. Standalone and replay output
default to amplitude 1, preserving the original mix.

The NightPad settings file retains version 1 with an optional `master_volume`
integer from 0 to 100. Older files default to 100. Invalid values leave the
current settings intact. A failed output change is reported and the host
attempts to restore its preceding setting on both engines before returning.
Original codename/save formats are untouched.

`scripts/test_master_volume.sh` compiles the actual mixer and movie backend,
captures final postmix PCM through SDL's dummy device, and verifies game-only,
combined game/movie, live half-volume, exact mute, unmute, independent movie
pause, clock progression while muted, invalid input and new-session voices.
`scripts/test_settings.sh` covers defaults, round trips, endpoints and invalid
files. The private evidence index records build, replay and simulator scope.
These checks do not establish physical listening quality, route changes,
interruptions, HRTF or reverb fidelity.
