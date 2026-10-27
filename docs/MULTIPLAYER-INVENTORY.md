# Multiplayer inventory

Status: **partial**. Limits, modes, maps, weapon sets and the Enviro-Mods
options come from the reconstructed source; match behaviour is not yet run.

## Slots and layout

- Four human players (slots 0-3) and six bots (slots 4-9), ten agents in all
  (`src/action/game/mp/MPLimits.h`).
- Split screen supports horizontal and vertical layouts
  (`SplitLayout` in `multiplayer.h`).
- AI bots are disabled on Ravine by the setup wheel's own rule.

## Modes

`MultiplayerGameMode` in `src/action/game/mp/multiplayer.h` defines the
shipped modes: Quick, Arena, Top Agent, Assassin, Team Arena, Capture the Flag,
Demolition, Protection, Blueprint, Goldeneye, King of the Hill, Uplink and Team
King of the Hill. One enum value (`GM_20`) has no name in the source and is
recorded as unknown.

Arena and Team Arena score victories; the scored modes use points. Kills do not
score in Arena or King of the Hill. `multiplayer_modes.cpp` holds the King of
the Hill and Uplink updates and the kill/scoring path.

## Weapon sets

Normal, Pistols, Automatic, Snipers, Explosives, Explosives 2, MI6, Phoenix,
Modern, Stealthy and Random.

## Enviro-Mods

The environment page (`ui_mp.cpp`) exposes:

- Respawn: near, far or random.
- Gun emplacements: on or off.
- Explosive scenery: on or off when unlocked.
- Grapple: on or off.
- Mini vehicles: off, RC tank, RC helicopter or random.

## Player settings

Each agent has a name, team (Phoenix, MI6 or none), skin chosen at launch, a
radar toggle and a health modifier used as a handicap or boost. The original
Player Mods page edits these per participant.

## Maps

The ten map names are listed in [CAMPAIGN-INVENTORY.md](CAMPAIGN-INVENTORY.md):
SpaceStation, Facility, Atlantis, SkyRail, SubPen, StealthShip, FortKnox,
MissileSilo, SnowBlind and Ravine. Two maps are marked incompatible with bots or
miniature vehicles in the front-end text.

## Still missing

- Which modes each map supports, and the win-condition details per mode.
- Character and weapon unlock dependencies.
- Bot behaviour at six bots and team composition rules.
- Actual matches: kills, respawns, scoring, results and a second match.
- Touch plus controller port assignment during a match.
