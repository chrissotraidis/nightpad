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

## Campaign order

| # | Mission | Objective (summary) | Text label |
| --- | --- | --- | --- |
| 0 | Training | Learn the basic weapons and gadgets in Q's evaluation centre. | `0x03000000` |
| 1 | Paris Prelude | Stop a rogue faction disrupting the New Year celebrations in Paris. | `0x03000001` |
| 2 | The Exchange | Reach Drake's reception and meet the undercover agents. | `0x03000002` |
| 3 | Alpine Escape | Escape with Zoe on an armoured snowmobile. | `0x03000003` |
| 4 | Enemies Vanquished | Reach the extraction point and Q. | `0x03000004` |
| 5 | Double Cross | Meet Mayhew, a traitor inside Drake's organisation. | `0x03000005` |
| 6 | Night Shift | Enter Mayhew's headquarters and retrieve data from the company system. | `0x03000006` |
| 7 | Chain Reaction | Infiltrate the decommissioned nuclear plant. | `0x03000007` |
| 8 | Hidden Agenda | Discover how Drake is secretly using the plant. | `0x03000008` |
| 9 | Phoenix Fire | Escape Kiko's trap and leave the skyscraper. | `0x03000009` |
| 10 | Streets of Tokyo | Flee the scene toward Q's mobile headquarters. | `0x0300000a` |
| 11 | Atoll Infiltration | Approach Drake's island base using Q's Vanquish. | `0x0300000b` |
| 12 | Deep Descent | Reach the private island without being detected. | `0x0300000c` |
| 13 | Island Caves | Sabotage the radar jamming devices to open the way for MI6. | `0x0300000d` |
| 14 | Island Infiltration | Destroy the air-defence system protecting the island. | `0x0300000e` |
| 15 | River Gauntlet | Infiltrate Drake's Disarmament Facility. | `0x0300000f` |
| 16 | Countdown | Enter the underwater base covertly and pursue Drake. | `0x03000010` |
| 17 | Equinox | Stop the takeover of the missile-defence platform. | `0x03000011` |

The front-end mission wheel (`src/action/ui/ui_nightfire.cpp`) contains twelve
selectable missions and names the level each one starts on. The text bank lists
eighteen campaign headings; the six extra names (Training, Hidden Agenda,
Streets of Tokyo, Atoll Infiltration, Island Caves, River Gauntlet) are not on
the wheel and are most likely a tutorial, sub-sections or unused strings. That
distinction is not yet verified.

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

- Mission-to-level-script and mission-to-drive-bundle mapping.
- Per-mission start/end state, movies, saves and unique inputs.
- The original difficulty ladder and failure/restart routes.
- Any device-specific rendering differences.
