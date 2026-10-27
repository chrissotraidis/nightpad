# Campaign inventory

Status: **partial**. Names and mission order come from the game's own front-end
text bank, which the action engine now dumps when `DumpFiles=on`. Objectives
below are original one-line summaries, not the retail strings. The raw bank and
the dumped files stay in ignored `build/` output.

## Provenance

1. `DumpFiles=on` in the action engine's `settings.ini`. The standalone build
   previously stubbed this documented option; patch 0016 restores it.
2. Boot the action engine once (the lifecycle harness is enough) and read
   `dump/UKTxt.Dat`.
3. `python3 vendor/nightfire/tools/ui/text_bank.py dump/UKTxt.Dat`. Campaign
   entries are bank 3, `0x03000000` through `0x03000011`; the multiplayer map
   names follow at `0x03000024`.

## Bank order

Rows marked \* are chapters inside a mission, not selectable starts; the
section below explains why.

| # | Heading | Objective (summary) | Text label |
| --- | --- | --- | --- |
| 0 | Training * | Learn the basic weapons and gadgets in Q's evaluation centre. | `0x03000000` |
| 1 | Paris Prelude | Stop a rogue faction disrupting the New Year celebrations in Paris. | `0x03000001` |
| 2 | The Exchange | Reach Drake's reception and meet the undercover agents. | `0x03000002` |
| 3 | Alpine Escape | Escape with Zoe on an armoured snowmobile. | `0x03000003` |
| 4 | Enemies Vanquished | Reach the extraction point and Q. | `0x03000004` |
| 5 | Double Cross | Meet Mayhew, a traitor inside Drake's organisation. | `0x03000005` |
| 6 | Night Shift | Enter Mayhew's headquarters and retrieve data from the company system. | `0x03000006` |
| 7 | Chain Reaction | Infiltrate the decommissioned nuclear plant. | `0x03000007` |
| 8 | Hidden Agenda * | Discover how Drake is secretly using the plant. | `0x03000008` |
| 9 | Phoenix Fire | Escape Kiko's trap and leave the skyscraper. | `0x03000009` |
| 10 | Streets of Tokyo * | Flee the scene toward Q's mobile headquarters. | `0x0300000a` |
| 11 | Atoll Infiltration * | Approach Drake's island base using Q's Vanquish. | `0x0300000b` |
| 12 | Deep Descent | Reach the private island without being detected. | `0x0300000c` |
| 13 | Island Caves * | Sabotage the radar jamming devices to open the way for MI6. | `0x0300000d` |
| 14 | Island Infiltration | Destroy the air-defence system protecting the island. | `0x0300000e` |
| 15 | River Gauntlet * | Infiltrate Drake's Disarmament Facility. | `0x0300000f` |
| 16 | Countdown | Enter the underwater base covertly and pursue Drake. | `0x03000010` |
| 17 | Equinox | Stop the takeover of the missile-defence platform. | `0x03000011` |

The front-end mission wheel (`src/action/ui/ui_nightfire.cpp`) contains twelve
selectable missions and names the level each one starts on. The text bank lists
eighteen campaign headings. The six extra names are chapters inside those
twelve missions, not selectable entries.

### The six headings that are not on the wheel

The bank stores a heading and a description for every campaign chapter, in
play order: `0x03000000`-`0x03000011` are headings and `0x03000012`-
`0x03000023` are their descriptions, one for one. The engine names eleven of
those headings in `assets.h`; its twelfth mission, Countdown, uses a different
id (`0x03000034`). Nothing in the recovered source refers to the remaining
seven bank ids: the six chapters below and a second copy of "Countdown" at
`0x03000010`. Their descriptions name beats the wheel missions must cross:

| Id | Heading | Description (shortened) | Chapter it belongs to |
| --- | --- | --- | --- |
| `0x03000000` | Training | Learn basic weapon and gadget skills in Q's evaluation centre. | Tutorial before Paris Prelude |
| `0x03000008` | Hidden Agenda | Determine how Drake is secretly using the decommissioned power plant. | Second half of Chain Reaction |
| `0x0300000a` | Streets of Tokyo | Flee the scene and head for Q's mobile headquarters. | Second half of Phoenix Fire |
| `0x0300000b` | Atoll Infiltration | Use the special abilities of Q's Vanquish to infiltrate Drake's secret island base. | Approach before Deep Descent |
| `0x0300000d` | Island Caves | Sabotage the island's radar jamming devices so you can open the way for MI6 forces. | Caves between Deep Descent and Island Infiltration |
| `0x0300000f` | River Gauntlet | Infiltrate Drake's Disarmament Facility. | Approach before Countdown |

The level table backs this reading where it can: `Cut_Level1`-`Cut_Level3`
(`0x0700000e`-`0x07000010`) exist but belong to no wheel mission, and the
supplied data has no separate atoll driving bundle. So the extra chapters are
either merged into the shipped levels or were cut, and their strings outlived
them. NightPad therefore lists twelve campaign missions and never offers the
other six as starts.

| Mission | Start level | Level id | Kind |
| --- | --- | --- | --- |
| Paris Prelude | `HT_Level_Driving_Paris` | 0x09000001 | driving |
| The Exchange | `HT_Level_CastleExterior` | 0x07000005 | action |
| Alpine Escape | `HT_Level_Driving_SnowMobile` | 0x09000005 | driving |
| Enemies Vanquished | `HT_Level_Driving_Alps` | 0x09000006 | driving |
| Double Cross | `HT_Level_HendersonA` | 0x07000001 | action |
| Night Shift | `HT_Level_TowerA` | 0x07000009 | action |
| Chain Reaction | `HT_Level_PowerStationA1` | 0x0700000c | action |
| Phoenix Fire | `HT_Level_Tower2A` | 0x07000011 | action |
| Deep Descent | `HT_Level_Driving_Underwater` | 0x09000002 | driving |
| Island Infiltration | `HT_Level_Driving_JungleA` | 0x09000003 | driving |
| Countdown | `HT_Level_EvilBase` | 0x07000014 | action |
| Equinox | `HT_Level_SpaceStationD` | 0x0700001b | action |

The driving bundles now line up with the wheel: `paris_mis01` for Paris
Prelude, `snow1a_mis3` for Alpine Escape, `snow2a_mis4` for Enemies
Vanquished, `uw_mis11` for Deep Descent, and `junglea/b/c_mis13` for Island
Infiltration.

### Level chains

`src/action/game/sp/Mission.cpp` lists the levels in order inside each mission:

| Chain | Levels |
| --- | --- |
| Castle | CastleExterior, CastleCourtyard, CastleIndoors1, CastleIndoors2 |
| Henderson | HendersonA, HendersonB, HendersonC, HendersonD |
| Tower | TowerA, TowerB, TowerC |
| Power Station | PowerStationA1, PowerStationA2 |
| Cut levels | Cut_Level1, Cut_Level2 |
| Tower 2 | Tower2A, Tower2B, Tower2Elevator, Tower2C |
| Caves | Cut_Level3 |
| Evil Base | EvilBase, EvilSilo, EvilBaseC |
| Space Station | SpaceStationD |

## Mission parts and objectives

`MissionData` in `src/action/game/sp/Mission.cpp` lists every action level with
its base map, its order inside that mission, and the objective array it points
at. The objective arrays hold text ids; the strings are in the ignored
`UKTxt.Dat` dump and are paraphrased here.

| Mission | Part (order) | Objectives |
| --- | --- | --- |
| The Exchange | CastleExterior (0) | Breach the castle walls. |
| | CastleCourtyard (1) | Get inside to the party. |
| | CastleIndoors1 (2) | Meet the undercover agents without breaking cover; observe the secret meeting. |
| | CastleIndoors2 (3) | Recover the guidance chip; escape with Zoe by gondola. |
| Double Cross | HendersonA (0) | Escort Mayhew to the bunker. |
| | HendersonB (1) | Destroy Mayhew's computer; rescue the geisha; find the servants' door. |
| | HendersonC (2) | Open the dragon safe; rescue Mayhew's servants; find the door to Mayhew. |
| | HendersonD (3) | Defeat the assassin. |
| Night Shift | TowerA (0) | Avoid raising the alarm; reach the lobby and activate the elevators; ride to the office floor. |
| | TowerB (1) | Install Q-Worm on the office systems; unlock the exterior door from the security centre; reach the balcony. |
| | TowerC (2) | Install Q-Worm on Mayhew's system; find the secure terminal; retrieve the files; reach the roof; parachute away. |
| Chain Reaction | PowerStationA1 (0) | Investigate ST-1; photograph the jetpack prototype; leave through TR-2. |
| | PowerStationA2 (1) | Investigate ST-3; photograph the laser prototype; destroy door C5 with the catwalk laser. |
| Phoenix Fire | Tower2A (0) | Escape the tower; reach the lower office floor. |
| | Tower2B (1) | Activate the elevator override; escape down the shaft. |
| | Tower2Elevator (2) | Reach the lobby. |
| | Tower2C (3) | Raise the security gate; leave by the front entrance. |
| Countdown | EvilBase (0) | Infiltrate undetected; follow Kiko; sabotage security; stop Rook cutting Delta's power; reach Delta. |
| | EvilSilo (1) | Find the exit to Omega Sector. |
| | EvilBaseC (2) | Reach the launch silo; stop Kiko launching. |
| Equinox | SpaceStationD (0) | Disable the missiles; defeat Drake before the station fails. |

Two base maps sit outside the wheel and hold the evidence for the cut
chapters above.

| Base map | Part (order) | Objectives |
| --- | --- | --- |
| Cut_Level1 | Cut_Level1 (0) | Disable the building security before using the lift: three systems. |
| | Cut_Level2 (1) | One placeholder objective. |
| Cut_Level3 | Cut_Level3 (0) | Three placeholder objectives. |

`Cut_Level1` and `Cut_Level2` most plausibly fill the "Hidden Agenda" chapter:
they follow the power plant and their only real objectives are about disabling
its security, but the second part keeps an unlocalised placeholder.
`Cut_Level3` is the "Island Caves" chapter - its objective array is even named
`Caves` - and has no real objectives at all. Both support the reading that
these chapters were dropped before their text was finished.

The five driving missions (Paris Prelude, Alpine Escape, Enemies Vanquished,
Deep Descent, Island Infiltration) have no `MissionData` rows: their goals are
handled inside the driving engine and still need inventorying.

### Where the driving objectives live

The driving HUD draws an objective message from its locale table
(`Hud::DrawObjectiveMessage` over `objectiveMsgId`), and that table ships in
`driving/misc.viv`: `data/gfx/locale/IDL_ENG.loc` and its siblings. The file is
a `LOCH` header, a `LOCI` index of 1530 big-endian offsets, then NUL-terminated
strings; each offset points inside its string, so the start is the previous
NUL. It extracts without the game, with the same BIGF and RefPack reader the
control-definition inventory already uses.

What is still missing is the attribution: the mission logic picks the text from
the track event data (`SetObjectiveComment` takes a locale id), so mapping a
string to Paris, Alpine and the rest needs a track parser. The strings
themselves stay in ignored output; only paraphrased notes belong here.

A headless boot is not enough. With a temporary log in `DrawObjectiveMessage`,
Mission 1 loaded its track and ran at 50 fps, but no objective was ever shown.
Holding the right trigger through the host-pad hook for ninety seconds changed
nothing, so the mission is still in its intro or waiting state and the events
that post an objective never fire. Both the log hook and the throttle hold were
removed rather than left as unproven engine/test changes. Attribution therefore
needs either the track parser or an interactive run that actually reaches the
first objective.

A second hook in `ESetObjective_MakeEvent_Callback`, which would print every
objective record as the track builds its events, also produced nothing in a
25-second boot or a 180-second one: the track's events are not created until
the mission reaches that stage. The longer log explains the delay - the direct
`-mission` boot takes the EU default video mode, asks for
`PAL\eng\paris_intro.mad`, misses it and only reaches its main loop about a
minute in. The app's real handover page is NTSC, so this is a harness default
rather than the product path, but it rules out sitting through the intro
quickly this way. That hook was removed too; the remaining routes are unchanged.

The track data itself can be read without the game. `scripts/inspect_driving_track.py`
walks the CARP group tree, finds the `Map ` group, lists its data families and
decodes the mission rules' event lists. Running it on Paris shows the method
works: the map group holds 114 rules, 754 triggers and 1391 event lists, and
`ESetObjective` (event 69) is present. Their comment words are zero, though, so
Paris's objective text must come from another event type - the families to
decode next are the ones carrying small text ids, such as 40 and 112. The
script prints those ids; it never prints the locale strings.

### The driving missions' text is the loading screen

Scanning every driving track shows the objective-comment route is a dead end:
only Paris has `ESetObjective` events, all with a zero comment, and the other
tracks have none. The missions' descriptions and hints are named by their loading
screen layouts instead (`data/loading/<track>.ini` inside `misc.viv`), which the
loading screen reads as `DESC_ID` and one of `HINT_ID1..` per launch:

| Mission | Track | Description id | Hint ids |
| --- | --- | --- | --- |
| Paris Prelude | paris_mis01 | 2800 | 2803 |
| Alpine Escape | snow1a_mis3 | 2900 | 2902-2908 |
| Enemies Vanquished | snow2a_mis4 | 3000 | 3005, 3007, 3006, 3008 |
| Deep Descent | uw_mis11 | 2650 | 2661, 2668, 2670-2672 |
| Island Infiltration | junglea_mis13a | 2753 | 2770, 2771 |

The ids are read through the driving locale file's indexed ids, so they do not
match the string table's own numbering; resolving them needs the `.loc` index
decoded. Until then this table is the mission-to-text mapping, with the strings
left in the game data.

The engine resolves them itself: a temporary print in `InitLoadScreen` showed
the description and every hint for each mission during a headless boot, without
decoding the `.loc` index. Paraphrased, the missions read:

| Mission | Goal | Hints (paraphrased) |
| --- | --- | --- |
| Paris Prelude | Keep Dominique safe | Use the sniper scope to take targets from range |
| Alpine Escape | Leave Drake's castle grounds | Try alternate ways to drop henchmen; armoured snowmobiles take work; follow Zoe's callouts; rockets hit hard but stray; oil barrels are volatile; use the weapon zoom; danger comes from every side |
| Enemies Vanquished | Reach Q at the extraction point | The Vanquish gadgets help; civilians must not be hurt; avoid police blockades; look for another route |
| Deep Descent | Get past the island's defences | Stay hidden until communications are down; use the terrain against torpedoes; mines can bring a cave down; firing gives you away; enemy subs cannot see behind them |
| Island Infiltration | Take the island's defences apart | Avoid Sentinel fire; Sentinels are very strong |

### How a part starts and ends

Starting a level part (`Mission_Init`) records its base map and order, then
resets the objectives of that part alone: each becomes hidden when it has a
reveal channel and not-shown otherwise. Player stats are reset only when the
loaded level is the mission's first part, so a later part keeps the stats the
earlier parts produced. A warm reset leaves earlier parts untouched.

Finishing every objective of the part sets the mission-won channel. The final
part of a mission then ends to its outro level — CastleIndoors2, HendersonD,
TowerC, PowerStationA2, Tower2C, EvilBaseC, SpaceStationD and Cut_Level2 all
have one — while the other parts hand off through their own level scripts. The
intermediate hand-offs are what the level chains above describe.

Failure is per channel, not per objective: a raised alarm, a killed civilian,
Kiko escaping in EvilBaseC or a launched missile in SpaceStationD each set the
fail channel with their own message, and death ends the level. Every failure
and death route opens the mission-end menu rather than the results page; a win
raises the stored base-map progress and shows the results.

No level part writes a save by itself. Leaving the results page saves the whole
profile (`LS_OPERATION_SAVE` with `SAVE_ALL` in `ui_nightfire.cpp`), so a
completed mission is persisted when the player continues past the results. A
failure or death never reaches that page, which is why the run is lost rather
than resumed at the last part.

## Driving content present in the supplied data

`driving/mis*.viv` holds seven mission bundles: `mis01`, `mis3`, `mis4`,
`mis11`, `mis13a`, `mis13b`, `mis13c`, each with `.mus` and localized `.spe`
files. The driving loop special-cases these names for intro and outro movies
(`paris_mis01`, `snow1a_mis3`, `snow2a_mis4`, `uw_mis11`, `junglea_mis13a`,
`jungleb_mis13b`, `junglec_mis13c`). Their exact placement in the campaign
table above still needs a run that names the requested mission when the
transition happens.

## Multiplayer maps named by the front end

Skyrail, Fort Knox, Snow Blind, Phoenix Base, Atlantis, Missile Silo, Sub Pen,
Ravine and Countdown. Descriptions exist in the same bank; two maps are marked
as incompatible with bots or miniature vehicles. Mode coverage, scoring
families and character/unlock dependencies are still to be inventoried in G08.

## Level table

The engine's hashcode table (`src/action/Hashcodes.h`) names every level and
gives its id. Campaign levels are `0x07000005`..`0x0700001c`; the multiplayer
maps are `0x07000021`..`0x07000029` plus `0x0700004b`.

| Id | Campaign level |
| --- | --- |
| 0x07000005 | CastleExterior |
| 0x07000006 | CastleCourtyard |
| 0x07000007 | CastleIndoors1 |
| 0x07000008 | CastleIndoors2 |
| 0x07000009 | TowerA |
| 0x0700000a | TowerB |
| 0x0700000b | TowerC |
| 0x0700000c | PowerStationA1 |
| 0x0700000d | PowerStationA2 |
| 0x0700000e | Cut_Level1 |
| 0x0700000f | Cut_Level2 |
| 0x07000010 | Cut_Level3 |
| 0x07000011 | Tower2A |
| 0x07000012 | Tower2B |
| 0x07000013 | Tower2C |
| 0x07000014 | EvilBase |
| 0x07000015 | EvilSilo |
| 0x07000016 | EvilBaseC |
| 0x07000018 | SpaceStationA |
| 0x07000019 | SpaceStationB |
| 0x0700001a | SpaceStationC |
| 0x0700001b | SpaceStationD |

| Id | Multiplayer level |
| --- | --- |
| 0x07000021 | SpaceStation |
| 0x07000022 | Facility |
| 0x07000023 | Atlantis |
| 0x07000024 | SkyRail |
| 0x07000025 | SubPen |
| 0x07000026 | StealthShip |
| 0x07000027 | FortKnox |
| 0x07000028 | MissileSilo |
| 0x07000029 | SnowBlind |
| 0x0700004b | Ravine |

The supplied recordings cover CastleExterior, CastleIndoors1, EvilBase,
HendersonA, PowerStationA1, SpaceStationD, Tower2A and TowerA. CastleExterior
also demonstrates a level transition: the recording starts on `0x07000005` and
reaches `0x07000006` before its final frames.

## Still missing

- Start and end state per mission part, including which part writes a save.
- Driving-mission objectives, which live outside `MissionData`.
- The original difficulty ladder and failure/restart routes.
- Any device-specific rendering differences.

## Mission media

The supplied `eurocom/30_fps` bundle holds sixteen XMV files whose names are
exactly the level hashcodes the engine assigns to mission intros and outros,
plus two menu loops: seven mission intros, seven mission outros and the loops.
They line up exactly with the seven action missions on the wheel.

| Mission | Intro (id) | Present | Outro (level, id) | Present |
| --- | --- | --- | --- | --- |
| The Exchange | CastleExterior `07100005` | yes | CastleIndoors2 `07300008` | yes |
| Double Cross | HendersonA `07100001` | yes | HendersonD `07300004` | yes |
| Night Shift | TowerA `07100009` | yes | TowerC `0730000b` | yes |
| Chain Reaction | PowerStationA1 `0710000c` | yes | PowerStationA2 `0730000d` | yes |
| Phoenix Fire | Tower2A `07100011` | yes | Tower2C `07300013` | yes |
| Countdown | EvilBase `07100014` | yes | EvilBaseC `07300017` | yes |
| Equinox | SpaceStationD `07100018` | yes | SpaceStationD `0730001b` | yes |

The two menu loops are `07330048` (background) and `07350048` (front end).
Other menu movies the engine knows (EA and MGM logos, trailer, attract movie)
are not in this bundle; the engine tolerates their absence.

The five driving missions play `.mad` movies from inside their `mis*.viv`
bundles (`paris_intro/outro`, `snow_intro/outro`, `alps_intro`,
`island_outro`, `ja_intro/outro`, `jc_intro/outro`). A real driving boot has
already played `NTSC\\eng\\paris_intro.mad` during the handoff gate, so that
path is exercised.

The known PAL gap is separate: the supplied image has only the `30_fps` movie
bundle, while one action recording expects a `25_fps` movie.

The engine maps every level to an intro id, not only mission starts. The
supplied bundle ships intros for the mission-start levels; a sub-level intro
such as CastleCourtyard's is requested and logged as "cannot open", and playback
continues. The CastleExterior recording crosses into that level and still
matches every frame.

NightPad writes `Region=NTSC` because the supplied image is the 30 fps movie
bundle. A PAL/25 fps run would look for files the image does not contain, which
is the recorded PAL media blocker rather than a NightPad setting.

## Difficulty, objectives and failure

The front end offers three difficulties (`ui_nightfire.cpp`): Operative,
Agent and 00 Agent, stored as `GameState.difficultyModifier` 1, 2 and 3.
`PlayerStats.cpp` branches on the value, so the ladder is engine-owned and
must be exercised through the original menu.

`Mission.cpp` tracks a mission through running, failed (fail text shown),
died, timed out, waiting, won and countdown states. The timed-out state shows
the results after a win and the retry menu otherwise, which is the path a
failure or death follows before a restart.

Each level's objective count comes from the same table:

| Mission chain | Level objectives |
| --- | --- |
| Castle | CastleExterior 1, CastleCourtyard 1, CastleIndoors1 2, CastleIndoors2 2 |
| Henderson | HendersonA 1, HendersonB 3, HendersonC 3, HendersonD 1 |
| Tower | TowerA 3, TowerB 3, TowerC 5 |
| Power Station | PowerStationA1 3, PowerStationA2 3 |
| Cut levels | Cut_Level1 4, Cut_Level2 1 |
| Tower 2 | Tower2A 2, Tower2B 2, Tower2Elevator 1, Tower2C 1 |
| Caves | Cut_Level3 3 |
| Evil Base | EvilBase 5, EvilSilo 1, EvilBaseC 2 |
| Space Station | SpaceStationD 2 |

The labels behind those objectives are retail text and stay in the ignored
dump; only the structure is recorded here.

## Secret Unlocks (R19)

The codename menu's Secret Unlocks page is engine-owned
(`ui_secrets.cpp`, `MenuUnlocks.cpp`). It holds 52 codes in five families:

- open every mission;
- toggle one mission on or off;
- add a whole reward set (multiplayer characters or scenarios);
- toggle one reward (a character or a multiplayer mode);
- grant one or more weapon and gadget upgrades.

Effects apply to the codename being edited. Mission codes flip that mission's
enable bit; if every mission would be closed, the first two are reopened. Reward
codes set or flip bits in the 64-bit reward mask, which also rebuilds that
player's gadget upgrades. Upgrade codes combine their upgrades with the mask as
it was before the code. The codename save persists the result.

An unmatched code returns "not applied": nothing changes and there is no success
message, matching the original. Some pairs are aliases; the first match wins.
The codes themselves are retail content and stay in the source and ignored
build output rather than this document.

Device test plan: enter one mission code twice (on, then off), a reward-set code,
a single-reward toggle, an upgrade code and an invalid string; save the codename,
relaunch, and confirm the unlocks and upgrades persisted while the invalid entry
left everything unchanged.
