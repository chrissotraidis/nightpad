# Decision 0022: native assist choices survive profile loads

Date: 2026-10-29

Loading an existing codename restores its CHET block, including immortality and
unlimited ammo. The original NightPad loop asserted enabled app choices every
frame but cleared disabled choices only when the requested bit mask changed.
Consequently an unchanged OFF choice could coexist with an enabled saved flag.
The native menu then understated the actual gameplay state.

A diagnostic Fort Knox/Uplink match exposed this: the isolated QA profile had
immortality in its protected original CHET block; the player took repeated hit
flashes without losing health. The native regression confirms both default-OFF
and returned-OFF profile loads fail, while ordinary on/off transitions pass.
The match's objective scoring/results are retained as diagnostic evidence only.
The fresh NPRUN campaign profile has CHET zero; its truck objective evidence is
unaffected, and it has still earned no whole-mission/results save.

Patch 0036 reconciles both flags after every action iteration when the app owns
them. The runtime setters claim ownership with bit 31 of the existing request
word, even for OFF. Without a runtime setter, the standalone/replay engine keeps
its original saved-cheat behavior. This avoids changing recording semantics.
Only the two supported native assists are managed; AllWeapons is untouched.
No new bridge exports, profile formats or progression writes are introduced.

The regression pauses the actual engine, encodes and loads the production CHET
block, resumes the normal loop and waits for two observed frame boundaries.
It checks unowned profile behavior, default OFF versus loaded ON, requested ON
versus loaded OFF, and returned OFF versus loaded ON. It verifies AllWeapons is
preserved and the engine stops/joins. Before: unowned/on cases pass, both OFF
load cases fail. After: all cases pass. The unchanged CastleIndoors1 recording
still matches all 635 frames; patch reconstruction passes (36 patches, 83 files).
Both iOS lanes and quick gates pass. Full engine regression and unsigned Release packaging also pass. The installed
simulator binary matches the build. Original NPQA load with stored immortality
now permits guard damage and death with native OFF; Replay succeeds, explicit ON
retains full health under sustained fire, and OFF restores death. All profile
files remain unchanged and native choices are restored OFF. Physical acceptance
remains open.

Evidence: `build/tests/assist-profile/`,
`evidence/action-demos/20261029T033842Z/results.json`, and
`evidence/multiplayer-uplink/result-before-fix.json`.
