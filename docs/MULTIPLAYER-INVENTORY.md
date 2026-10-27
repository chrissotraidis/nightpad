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

### Map-specific rules

- Ravine disables the AI Bots option in the setup wheel and the bot list is
  emptied for that map.
- `Car_Create` refuses to spawn a mini vehicle on Ravine, so the mini-vehicle
  setting has no effect there.
- Every multiplayer map applies standard drone tuning with the multiplayer
  body-part damage modifiers; no map changes the mode rules in source.

### Mode availability

No source check ties a game mode to a map. The setup wheel offers every mode on
every map, and the only map-level exception is bots/vehicles on Ravine. That
should still be confirmed by playing each mode family on at least two maps.

### Unlock matrix

The scenario wheel holds thirteen modes. Seven are available by default:
Quick Game, Arena, Team Arena, Capture the Flag, Top Agent, Espionage/Blueprint
and King of the Hill. Six are earned rewards: Uplink, Demolition, Protection,
GoldenEye Strike, Assassination and Team King of the Hill. Explosive Scenery is
also reward-gated.

The character wheel has 29 entries. Indices 12-28 (17 characters) are locked
until a reward bit or Secret Unlock grants them; the first twelve are available
by default. Mission medals and codes both feed the same reward mask, so either
route opens the same set, and the codename save persists it.

### Match rules

- Duration is chosen in minutes: 1-10, then five-minute steps to 60, or
  Unlimited.
- The second selector offers 1-10 then five-point steps to 120. It is labelled
  Lives for Top Agent and Points otherwise.
- Scoring: Arena and Team Arena report victories; Top Agent, Assassination,
  CTF, Demolition, Protection, Blueprint, GoldenEye Strike, King of the Hill,
  Uplink and Team King of the Hill report points. Quick Game reports no generic
  score because its mode owns the result. Team scores sum the players' points.
- Kills do not score in Arena or King of the Hill.

### Bot setup

Each of the six bot slots has:

- Playing: yes or no.
- Accuracy: poor, average, good or very good.
- Aggression: normal, high or very high.
- Speed: slow, normal or fast.
- Health: 50, 75, 100, 125, 150, 175, 200, 250 or 300.
- Reaction and recovery: 50 to 200 in seven steps.
- Personality, which depends on the bot's side. The good side offers none,
  judge, collector, guardian or team player; the other side offers none,
  berserker, greedy, vengeful or assassin.

Characters with a skin index of 15 or above use fixed stats and cannot edit
these values. One-per-game characters (Bond and the good-side bots) are handed
back when the bot is benched or stops playing.

## Still missing

- Which modes each map supports, and the win-condition details per mode.
- Character and weapon unlock dependencies.
- Bot behaviour at six bots and team composition rules.
- Actual matches: kills, respawns, scoring, results and a second match.
- Touch plus controller port assignment during a match.
