# Cheat and modification research

Status: **research only**. Nothing here is implemented in the app yet, and no
cheat may appear in core acceptance runs.

## What the game already contains

`src/action/ui/ui_cheats.cpp` implements the original debug menu's checkboxes.
Each one writes a global the game already reads:

| Option | State it drives | Effect | Product candidate |
| --- | --- | --- | --- |
| Music | `SoundInfo` low word | Music on/off | no |
| Draw everything | `switch_ForceDrawAll` | Draws every object | no (perf) |
| Widescreen | `switch_CONFIG_WIDESCREEN`, `IsWidescreen` | Recomputes every camera | already exposed |
| Fly | `debug_scanmode`, `debug_clipmode` | Player 0 flies and clips | no |
| Drones | `switch_NO_DRONES` | Drones run or stop | no |
| Blind drones | `switch_BLIND_DRONES` | Drones stop attacking | no |
| All weapons | `CheatInfo.AllWeapons`, `UnlimitedAmmo` | Equips every weapon and gadget, full ammo, armour | yes |
| Immortal | `CheatInfo.Immortal` | Player takes no damage, including drowning | yes |
| HUD | `hud_state` | All HUD panes and crosshairs | no |
| Debug sprites | `Drone_DebugSpr` | Debug markers | no |
| Coordinates | `switch_SHOW_COORDS` | Position readout | no |
| Allow freeze | `switch_allowFreeze` | Game may freeze | no |
| Dummy player | `Drone_DummyPlayer` | Makes player 0 inert | no |
| Zero gravity | `zero_gravity` | Player 0 floats | no |
| Debug lockup | `bDebugLockup` | Debugger parking | no |
| Tweak brightness | `bTweakBrightness` | Brightness override | no |
| Unlock everything | `menu_unlock_everything` | Marks content unlocked | careful; progression |
| Debug controls | `bDebugControls` | Debug input | no |

The game's own comment notes that loading a codename resets `CheatInfo`, so an
assist must be applied after the level loads rather than once at launch.

## Recommended allowlist

1. **Immortal** — one flag read by the damage path; safe to turn off at any time.
2. **Unlimited ammo and all weapons** — also one flag plus a one-time equip; the
   equip must only run once player 0 exists.

Both would be app-owned toggles, off by default, shown in an Assists submenu,
reset on game stop, and excluded from every campaign acceptance run. Unlocking
content stays with the original Secret Unlocks screen rather than a blanket
switch.

## Integration plan

- Engine bridge setter for the two flags, called on the game thread after a
  level is live (or at the engine's first frame).
- App settings entries with explicit labels that warn they change gameplay.
- Behaviour test: flag off, on, off again across a death and a level restart.
- Confirm the flags do not leak into driving sessions or multiplayer.

## Open questions

- Whether the debug page is reachable in this build without a devtool command.
- Whether `AllWeapons` survives a level transition or must be re-applied.
- Whether any assist interferes with recording playback (it must not).
- Which original Secret Unlocks codes remain valid; that belongs to R19.
