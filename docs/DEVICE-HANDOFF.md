# Device handoff

Status: the build is ready; the machine has no signing identity and no
connected device, so every physical acceptance gate is waiting on this handoff.

## Prerequisites

1. An Apple ID added to Xcode (Settings > Accounts) with a development team.
2. The device connected, unlocked and trusted, with Developer Mode enabled.
3. A unique bundle identifier for installation, for example
   `com.example.nightpad.shell`.

## One command

```sh
scripts/device_handoff.sh --install --team=<TEAMID> --bundle=com.example.nightpad.shell
```

Without `--install` the script only rebuilds the unsigned device shell, runs
the link check, and reports which prerequisites are missing. With `--install`
it signs a Release build, installs it with `devicectl`, and launches it with
the console attached. Add `--device=<UDID>` if automatic detection fails.

## What to exercise

Each pass adds evidence a simulator cannot give. Keep captures under the
ignored `evidence/device/<date>/`.

| Gate | Session | Expected result |
| --- | --- | --- |
| G03 | Install the probe app and run the pointer/Metal/media fixtures | Results match the simulator probe |
| G05 | Import the prepared data - copy it to `Documents/NightPad Import` first, then use the panel's "Use NightPad Folder"; try the picker path once too - relaunch, play, save | Ready state survives; saves untouched by import; both paths reach the same result |
| G05 | Share the saves, then restore them with Import Saves (or copy them to `Documents/Save Import` and use "Restore Saves from NightPad Folder") and answer the replace prompt | Restored files match the export; unrelated saves stay untouched |
| G06 | Touch: move/look/fire/aim, five fingers, sustained combat grip | No dropped inputs, controls reachable, menu independent |
| G06 | Controller: connect, held buttons, sleep/wake, P2 join | Ports stay separate; touch P1 not stolen; rumble routed |
| G06 | Edit the layout, Save, relaunch, Reset; long-press a control to hide and show it | Geometry and visibility persist; every editor action remains reachable |
| G07 | First-play route: front end, Paris, a transition, save, relaunch | Transitions, media and saves work on device |
| G09 | Original and 2x targets, 4:3 and 16:9, FXAA off/on | Correct fit, no scope/HUD regressions, sustained frame rate |
| G09 | Secret Unlocks: mission toggle, reward set, upgrade, invalid code, save/relaunch | Unlocks persist; invalid code changes nothing |
| G12 | Ten start/stop cycles, backgrounding, thermal run | Every session joins; memory plateaus; no crash |

## Evidence to bring back

- The in-app Diagnostics report (three-dot menu > Info > Diagnostics > Share).
- Screenshots of the home screen, menu, touch overlay, layout editor and each
  display mode.
- Notes for each controller and touch session: device model, iOS version,
  controller model, what was held, and any stutter or drop.
- Console output from the handoff script for any crash or transition.

## If the script cannot sign

1. `xcrun devicectl list devices` must show the device as connected.
2. `security find-identity -v -p codesigning` must list a valid identity.
3. In Xcode, open `build/ios-shell-device/NightPadPlatformProbe.xcodeproj`,
   choose the NightPadShell scheme, set the team and bundle id, and run on the
   device.

`scripts/package_device_app.sh` builds the Release app and writes an unsigned
`build/package/NightPadShell-unsigned.ipa` for inspection. It is not
installable until it is signed.

## Freezing the candidate

```sh
scripts/freeze_candidate.sh          # quick gates, package, identity
scripts/freeze_candidate.sh --full   # adds the slow engine suite
```

It refuses a dirty tree, runs the gates in order, rebuilds the unsigned package
and prints the identity, writing the whole run to
`build/package/candidate.txt`. Device acceptance is never claimed by it.

`scripts/freeze_candidate.sh` rebuilds the package and records its hash in
`build/package/candidate.txt`. The last manual build was
`ee803d577fb6ab1e70c540ac5f2244c03e5c348eca93ad83e817d20ff2193d10` (app code
at `ba3a56e`). Do not install a stale copy.

## Not in this candidate

Texture overrides are decided off for this pass: the engine's DDS replacement
belongs to the D3D9 backend and is not wired into the SDL/Metal backend
(`docs/DECISIONS/0013-texture-overrides.md`). Do not create a `textures` folder
expecting it to change anything.

## What cannot be claimed before this pass

Physical touch ergonomics, controller reconnect and rumble feel, real device
performance at higher render targets, and the campaign route do not have
evidence. The simulator checks and macOS engine gates do not substitute for
them.
