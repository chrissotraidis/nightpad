# NightPad

NightPad brings the **original Xbox version of 007: Nightfire** to iPhone and
iPad as a native ARM64 app. It combines the reconstructed
[nightfire-cxbx](https://github.com/NightfireResearch/nightfire-cxbx) action and
driving engines with an Apple shell, Xbox touch controls, and local gamepad
support. Rendering uses SDL GPU on Metal; movies use FFmpeg.

**Work in progress.** The real game runs in the iPhone Simulator, including
original menus, action play through the Exchange party entrance, driving
handoffs, and local bot matches. Complete campaign coverage, signed
physical-device play, touch comfort, audio fidelity, and
sustained device performance are still acceptance work. An unsigned build is
not a finished or installable private candidate. See [current status](docs/STATUS.md)
and the [test matrix](docs/TEST-MATRIX.md) for the verified boundary.

## What is here

- The original action and driving engines in one app, with cooperative
  start/stop, engine transitions, and native-menu pause.
- Landscape phone and tablet controls: two sticks, D-pad, the Xbox A/B/X/Y
  diamond, LT/RT, White/Black, and separate Start/Back buttons.
- An editable touch layout with move, resize, visibility, opacity, Save,
  Cancel, and Reset. Phone and tablet layouts are stored separately.
- Native display settings for original through 4× rendering, 4:3/16:9,
  FXAA, and selected FOV values. A selectable setting is not a device
  performance endorsement; full visual-mode acceptance is still open.
- Persistent master volume for game and movie audio, including mute.
- Prepared-data import, separate save storage, save export/restore,
  diagnostics, and original control references.
- Two optional action-engine assists, off by default: immortality and
  unlimited ammo. These do not apply to driving or core acceptance runs.

Original Secret Unlocks and multiplayer rules remain in the game's own menus.
Online/LAN play and external texture replacements are not delivered features.

## Requirements

You need an Apple Silicon Mac, full Xcode with the iOS and Simulator SDKs,
Git, Python 3, CMake, Ninja, and **your own original Xbox Nightfire disc data**.
No disc image, extracted retail files, movies, or saves are supplied here.
PC and PlayStation releases are not interchangeable inputs.

The recorded build uses Xcode 26.6 with iOS 26.5 SDKs. The app's deployment
target is iOS 16.0; that target alone does not prove support or acceptable
performance on every iOS 16 device. Exact toolchain and dependency versions are
in [config/toolchain.json](config/toolchain.json) and
[config/dependencies.lock.json](config/dependencies.lock.json).

## Build from a fresh checkout

Run these commands from the repository root. The dependency bootstrap is for
setting up a fresh checkout; preserve local engine changes before re-running it.

```sh
scripts/bootstrap_dependencies.sh
python3 scripts/prepare_game_data.py --iso /absolute/path/to/your-nightfire.iso

scripts/build_ffmpeg_ios.sh simulator
scripts/build_ios_engines.sh simulator
scripts/build_ios_shell.sh simulator
```

The preparation script lists and validates the image, hashes it, and extracts
it into ignored `build/data/` staging. `build/data/current.json` identifies the
prepared folder. The original image is not rewritten. Engine portability
changes live in numbered [patches](patches/); the bootstrap applies them to the
pinned upstream source.

The Simulator app is produced at:

```text
build/ios-shell-simulator/Debug-iphonesimulator/NightPadShell.app
```

Choose an available iPhone or iPad simulator in Xcode, keeping **one simulator
booted at a time** for this project's test runs. After booting it:

```sh
xcrun simctl list devices booted
xcrun simctl install <SIMULATOR_UDID> build/ios-shell-simulator/Debug-iphonesimulator/NightPadShell.app
xcrun simctl launch <SIMULATOR_UDID> local.nightpad.shell
```

Import the prepared folder through the app before starting the game.
Simulator rendering is useful development evidence and does not replace
physical phone/tablet acceptance.

## Import and play

1. Open **⋯ → Data & Saves → Game Data** and choose the prepared folder
   containing `manifest.json` and the extracted game directories. You can also
   copy that prepared folder's contents into the app's **NightPad Import**
   folder in Files and use **Import from NightPad Folder**.
2. Check **Data & Save Status** for readiness. Imported data and saves use
   separate storage; importing game data does not replace your codenames.
3. Choose **⋯ → Start Game**. Use the original front end to select or create a
   codename, choose difficulty, and play the campaign or local multiplayer.
4. **Xbox Start** opens the original pause menu. **⋯** opens NightPad's native
   menu and holds local gameplay/audio while it is open. Dismissing the last
   native screen resumes play; it does not cancel an original in-game pause.
5. **⋯ → Stop Game** ends the running session and returns to NightPad. Finish
   any original save operation first; stopping does not save an unfinished
   mission or preserve its live checkpoint.

The menu groups **Display, Controls, Audio, Enhancements, Data & Saves, Help &
Feedback**, then **Start/Stop Game**. Touch editing lives under Controls;
data and save operations have separate submenus. **Audio → Master Volume**
offers Muted, 25%, 50%, 75%, and 100%. Changes apply to game and movie output
and survive app relaunch. The default 100% preserves the original game's mix;
the game's own music/effects preferences still apply within that mix.

## Touch and controllers

The defaults place movement under the left thumb, looking inward on the right,
and the face buttons in Xbox order: **Y above, A below, X left, B right**.
LT/RT and White/Black sit above the main controls; Start and Back share a small
system-button row. The tablet uses its own composition.

Use **⋯ → Controls → Touch Controls → Edit Layout…** to arrange the controls.
Drag to move, pinch to resize, or hold a control for visibility and opacity.
Save commits the layout; Cancel leaves the saved layout alone. Reset adopts
the latest default, and takes effect persistently when you Save. Existing
custom layouts are retained across updates; use Reset if you want the new
arrangement.

The overlay forwards Xbox inputs; the original selected control scheme still
sets their meaning. Under the original Nightfire scheme, A crouches, Y jumps,
X reloads/interacts, B changes weapons, Black changes gadgets, Back controls
vision, and LT/RT retain the original aim/fire behavior. Driving has its own
original bindings. See the in-app **Control Guide**, [control schemes](docs/CONTROL-SCHEMES.md),
and [driving controls](docs/DRIVING-CONTROLS.md).

Apple GameController supplies physical controller input through four logical
player ports. Touch visibility can follow the controller assigned to the touch
player, with a manual override under Touch Controls. Reconnect, rumble feel,
practical simultaneous touch use, and four real controllers still need physical
device evidence.

## Saves and diagnostics

Use **⋯ → Data & Saves → Saves** to export saves or import a backup.
Restore is available while the engine is stopped and asks before replacing a
colliding save. The app's **Save Import** folder provides an alternative to the
Files picker. Keep an exported backup before device changes.

**⋯ → Help & Feedback** contains the control guide, diagnostics, and About.
Review a diagnostic report before sharing it. Retail data, saves, screenshots,
and signing material belong in ignored local storage, not Git.

## Physical builds

Build the device dependencies separately:

```sh
scripts/build_ffmpeg_ios.sh device
scripts/build_ios_engines.sh device
scripts/build_ios_shell.sh device
scripts/package_device_app.sh
```

The package is `build/package/NightPadShell-unsigned.ipa`. It must be signed
before installation. With a legitimate development team, signing identity,
and a connected, trusted device with Developer Mode enabled:

```sh
scripts/device_handoff.sh --install --team=<TEAM_ID> --bundle=com.example.nightpad.shell
```

The [device handoff](docs/DEVICE-HANDOFF.md) explains signing, installation,
and the phone/tablet sessions still required. The project does not obtain
certificates, change device security, or publish a build automatically.

## Verification and current limits

```sh
scripts/test_touch_layout.sh   # geometry, targets, persistence
scripts/test_touch_input.sh    # Xbox input semantics and simultaneous touches
scripts/verify_quick.sh        # host logic, both iOS shell lanes, links, privacy, patches
scripts/verify_engine.sh       # slower actual-engine regression suite
```

The latest smoke check passes clean Stop/Start, title/front-end touch input,
menu access, and preservation of existing saves and layouts. The quick suite
also passes host tests and both iOS shell build lanes. This is simulator and
build verification; earned mission-save/relaunch and physical play remain
unverified.

The current engine patch stack reproduces 38 patches across 85 files. Native
lifecycle, save durability, input, and focused simulator checks have passed on
their recorded scopes. Eleven unchanged action recordings cover 208,364
frames on an earlier recorded candidate; they are not a continuous campaign
completion claim. The supplied 30 fps media set is missing a PAL ending movie
required by the remaining baseline recording. See [known issues](docs/KNOWN-ISSUES.md)
for that dependency and outstanding audio, display, campaign, and device work.

Use [STATUS](docs/STATUS.md) for current progress, [TEST-MATRIX](docs/TEST-MATRIX.md)
for evidence, [UPSTREAM-DELTA](docs/UPSTREAM-DELTA.md) for engine changes, and
[GOAL-JOURNAL](docs/GOAL-JOURNAL.md) for iteration history. The product contract
is [NIGHTPAD_PRD](docs/NIGHTPAD_PRD.md); the execution loop is
[NIGHTPAD_GOAL_LOOP](docs/NIGHTPAD_GOAL_LOOP.md).

## Source and data boundaries

The maintained engine and Apple UX references are pinned in the dependency
manifest. GalaxyPad is the primary Apple shell/menu/editor reference, with
SunPad as a secondary input and dual-stick reference. Neither donor's game
nor console runtime is bundled as NightPad gameplay.

The upstream engine has no reviewed first-party license file. Provenance and
public distribution remain separate decisions; see [PROVENANCE](docs/PROVENANCE.md).
Do not commit or distribute retail images, extracted assets, saves, private
captures, or signing material.
