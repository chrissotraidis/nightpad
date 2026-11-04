# NightPad

NightPad brings the **original Xbox version of 007: Nightfire to iPhone and iPad
as a native ARM64 app**. It is built from
[nightfire-cxbx](https://github.com/NightfireResearch/nightfire-cxbx), a fan
project that rebuilt the Xbox game's own code function by function, and adds an
Apple shell with touch controls, controller support, a native settings menu,
cheats, save tools and personal builds through
[PadMint](https://github.com/chrissotraidis/padmint).

**AI disclosure:** NightPad uses substantial AI assistance for code, tests,
documentation, debugging and maintenance. There is no audited percentage of
AI-generated code; the test and device records below state what has actually
been checked. This describes NightPad's workflow, not the authorship of the
upstream engine.

<p align="center">
  <img src="apple/ios/Assets.xcassets/AppIcon.appiconset/AppIcon.png" alt="NightPad app icon" width="160">
</p>

<p align="center">
  <strong>007: Nightfire, native on iPhone and iPad.</strong><br>
  On-foot and driving missions, split-screen bot matches and the original menus.<br>
  Touch or controller. Your own game. No emulator or JIT.
</p>

<p align="center">
  <img alt="iOS and iPadOS 16 or later" src="https://img.shields.io/badge/iOS%20%2F%20iPadOS-16%2B-0A84FF?logo=apple">
  <img alt="Native ARM64" src="https://img.shields.io/badge/runtime-native%20ARM64-30D158">
  <img alt="SDL GPU on Metal" src="https://img.shields.io/badge/renderer-SDL%20GPU%20%E2%86%92%20Metal-5E5CE6">
  <img alt="Version 0.2.0 preview" src="https://img.shields.io/badge/version-0.2.0%20preview-FF9F0A">
  <img alt="Game data not included" src="https://img.shields.io/badge/game%20data-not%20included-FF453A">
  <a href="https://github.com/chrissotraidis/padmint"><img alt="Build with PadMint" src="https://img.shields.io/badge/PadMint-build%20your%20own-3EB489"></a>
  <a href="https://discord.gg/xwHfUD2bxW"><img alt="Join the Discord community" src="https://img.shields.io/badge/Discord-Join%20the%20community-5865F2?logo=discord&amp;logoColor=white"></a>
</p>

<p align="center">
  <a href="#get-nightpad">Get NightPad</a> ·
  <a href="#testing-status">Testing status</a> ·
  <a href="#controls">Controls</a> ·
  <a href="#display-and-resolution">Display</a> ·
  <a href="#known-issues">Known issues</a> ·
  <a href="#refinement-plan">Refinement plan</a> ·
  <a href="#frequently-asked-questions">FAQ</a>
</p>

> [!IMPORTANT]
> **Build your own copy on an Apple Silicon Mac.** NightPad releases contain a
> PadMint recipe and checksums, with source in this repository. No prebuilt app,
> disc image or game data is distributed. You need **your own original Xbox
> 007: Nightfire disc image**; PadMint turns it into the game data folder you
> import into the app.

## Highlights

- **Native ARM64 play.** The rebuilt action and driving engines run inside one
  app and hand over to each other as the story moves between on-foot and
  driving missions. Rendering uses SDL GPU on Metal; movies use FFmpeg.
- **Touch and controllers.** Two sticks, D-pad, the Xbox A/B/X/Y diamond,
  LT/RT, the Black and White buttons and Start/Back, in an editable layout.
  Controllers connect through Apple's GameController, and the touch overlay can
  hide itself while a controller is in use.
- **A familiar ⋯ menu.** Display, controls, audio, cheats, data and saves, help
  and Start/Stop, in the same style as the other ports. Opening it holds the
  game, its timers and its audio until you close it.
- **Sharper picture.** Render at the original 640×480 or at 2×, 3× or 4×
  (2560×1920), with FXAA, a 16:9 option and wider fields of view.
- **Nightfire controls by default.** New codenames start on the game's own
  Nightfire scheme, with RB (the Black button beside the right trigger)
  switching weapons.
- **Cheats built on the game's own switches.** Immortality, Unlimited Ammo, All
  Weapons and Unlock All Content, all off until you turn them on.
- **Your saves stay yours.** Game data and saves are stored separately, and you
  can export, restore and back up saves from the app.
- **Personal builds with PadMint.** Pinned sources, one build command, and a
  checked game data folder made from your disc.

## What is available now?

| Platform or route | Status |
|---|---|
| iPad, iPadOS 16+ | Personal unsigned IPA built on an Apple Silicon Mac. Played on an iPad Pro 12.9-inch |
| iPhone, iOS 16+ | Same IPA with a phone touch layout; tested in the iPhone Simulator only |
| PadMint | iPhone/iPad builds through the NightPad recipe (see [Get NightPad](#get-nightpad)) |
| Mac, Windows, Linux, Android, Apple TV | Not offered by NightPad. The upstream engine builds for Windows, Linux and Mac on its own |
| App Store, TestFlight, prebuilt apps | Not offered |
| Online or LAN play | Not offered. A deferred plan is in [NETPLAY-PLAN](docs/NETPLAY-PLAN.md) |

**NightPad 0.2.0 is a preview.** The maintainer plays it on a physical iPad
with touch controls and an Xbox controller, and the display, render resolution,
controls and in-level audio are confirmed there. A complete campaign run, long
sessions, iPhone hardware and four-player split screen with real controllers
have not been checked yet. The [testing status](#testing-status) below lists
exactly what has.

## Get NightPad

You need:

- An **Apple Silicon Mac** with full **Xcode and its iOS platform**, plus
  Homebrew for CMake. Command Line Tools alone are not enough.
- At least **12 GB free** for the first build. The build and its game data
  folder take about 5 GB; the rest is headroom.
- **Your own original Xbox 007: Nightfire disc image** as an ISO or XISO. PC,
  GameCube and PlayStation 2 versions are different games and do not work.
- An iPhone or iPad on **iOS/iPadOS 16 or newer**, and a way to sign and install
  a personal IPA: Xcode with your own Apple developer team, AltStore Classic,
  SideStore or Sideloadly.

### Build for iPhone/iPad with PadMint

1. Install CMake once: `brew install cmake`.
2. Download [PadMint](https://github.com/chrissotraidis/padmint/releases/latest),
   unzip it and open `PadMint.command`.
3. Choose **NightPad → iPhone / iPad**, select your Nightfire disc image, then
   **Make my copy**. Keep the Mac awake and connected while it downloads the
   pinned sources and builds.
4. PadMint finishes with two things: your personal NightPad IPA and a
   **NightPad game data folder** extracted from your disc. Both are private;
   do not share them.
5. Sign and install the IPA on your device.
6. Copy the NightPad game data folder to the device (Files, iCloud Drive or a
   USB drive). In NightPad choose **⋯ → Data & Saves → Game Data → Import
   Prepared Game Data…** and pick that folder. Then choose **⋯ → Start Game**.

PadMint only reads your disc image. It checks the image's file listing, hashes
it before and after extraction, and refuses an image that is missing the game's
executables or its `eurocom` and `driving` folders. The first build
downloads the engine, SDL, FFmpeg and SPIRV-Cross sources; later builds reuse
them.

NightPad appears in PadMint once PadMint's catalog lists it. Until then,
[Build from source](#build-from-source) runs the same recipe.

### Build from source

```sh
brew install cmake
git clone https://github.com/chrissotraidis/nightpad.git
cd nightpad
scripts/build-personal-ipa.sh ~/Games/Nightfire.iso ~/Downloads/NightPad.ipa /tmp/nightpad-work
```

This is exactly what PadMint runs. It fetches the pinned upstream sources,
applies NightPad's numbered engine patches, extracts your disc into
`~/Downloads/NightPad.ipa.data` (the game data folder to import) and writes
the unsigned IPA to `~/Downloads/NightPad.ipa`.

To work step by step instead:

```sh
scripts/bootstrap_dependencies.sh
python3 scripts/prepare_game_data.py --iso /absolute/path/to/your-nightfire.iso

scripts/build_ffmpeg_ios.sh device
scripts/build_ios_engines.sh device
scripts/package_device_app.sh        # build/package/NightPadShell-unsigned.ipa
```

`prepare_game_data.py` writes the prepared folder under `build/data/`, and
`build/data/current.json` names it. Re-running the bootstrap on a checkout
with engine changes checks them against the patch series instead of
overwriting them.

### Sign and install

With your own development team and a connected device in Developer Mode, the
helper signs and installs the app:

```sh
scripts/device_handoff.sh --install --team=<YOUR_TEAM_ID> --bundle=<your.bundle.id>
```

Use your own bundle identifier unless you are the maintainer. Sideloading tools
can install the unsigned IPA directly. See [DEVICE-HANDOFF](docs/DEVICE-HANDOFF.md)
for signing details and the device checklist.

**Updating:** install over your existing NightPad with the same signing and
bundle identifier. Your game data, codenames, saves, touch layout and settings
stay. Deleting the app deletes all of them, so export your saves first.

## Supported game

NightPad needs the **original Xbox release of 007: Nightfire** (Xbox title
`0x45410026`). It has been tested with one disc image: version 1, which
carries only the 30 fps (NTSC) movie set. The upstream engine project tests the
PAL disc. Other Xbox images that contain `default.xbe`, `Driving.xbe`,
`eurocom` and `driving` should prepare and import, but have not been
played through NightPad yet.

The PC, GameCube and PlayStation 2 versions of Nightfire are different games
and cannot be used.

## Playing

1. Open **⋯ → Start Game**. The original front end appears: create or pick a
   codename, choose a difficulty and play the campaign, or set up a
   multiplayer match with bots.
2. **Xbox Start** opens the game's own pause menu. **⋯** opens NightPad's menu
   and holds the game, its timers and its audio while it is open; closing the
   last NightPad screen resumes play.
3. **⋯ → Stop Game** ends the session and returns to NightPad. Finish any save
   in the game first: stopping does not save an unfinished mission.

The ⋯ menu groups **Display, Controls, Audio and Cheats**, then **Data & Saves**
and **Help & Feedback**, then **Start/Stop Game**. **Audio → Master Volume**
offers Muted, 25%, 50%, 75% and 100% for game and movie sound; the game's own
music and effects settings still apply inside that.

## Controls

### Touch

The default layout puts movement under the left thumb and looking under the
right, with the face buttons in Xbox order: **Y above, A below, X left, B
right**. On iPad, LT and RT sit above the sticks, the D-pad is at the left
edge, the A/B/X/Y diamond is in the right corner with Black and White above it,
and Start/Back are stacked at the right edge. Phones have their own layout.

A finger that starts on a stick, the D-pad or a trigger keeps that control even
if it slides past the edge, and a stick centres on wherever your thumb lands.

### Editing the layout

Open **⋯ → Controls → Touch Controls → Edit Layout…**:

- Tap a control to select it, drag to move it, and pinch or use the **Size**
  slider to resize it.
- The A/B/X/Y diamond, the Black/White pair and Start/Back move, resize and
  hide as one item, so their buttons always match.
- **Opacity** is one setting for the whole overlay.
- **Save** keeps the layout, **Cancel** discards your changes, and **Reset**
  restores the device default when you Save.

Phone and tablet layouts are stored separately. **Always Show** keeps the
overlay visible; **Auto-Hide** hides it while your controller is in use.

### Controllers

Apple's GameController supplies up to four controllers as players 1 to 4. An
Xbox controller has been tested on the iPad; other controllers that iOS
supports should work but are untested. **⋯ → Controls → Controller** shows how
many are connected and turns rumble on or off.

### Control schemes

New codenames start on the game's **Nightfire** scheme:

| Input | Action |
|---|---|
| Left stick | Move |
| Right stick | Look and aim |
| RT / LT | Fire / scope zoom |
| Y / A | Jump / crouch |
| X | Reload |
| White (LB) | Alternate fire |
| B, Black (RB) or D-pad right | Next weapon |
| D-pad left | Previous weapon |
| D-pad up / down | Next / previous gadget; zoom in / out while scoped |
| Back | Night vision |
| Start | Pause menu |

Codenames created before 0.2.0 keep their saved scheme (often Classic Bond)
until you change it in the game's **Controller Setup**. Driving has its own
original bindings. **⋯ → Help & Feedback → Control Guide** shows the mapping in
the app, and [CONTROL-SCHEMES](docs/CONTROL-SCHEMES.md) and
[DRIVING-CONTROLS](docs/DRIVING-CONTROLS.md) cover every scheme.

## Display and resolution

**⋯ → Display** offers:

| Setting | Options | Applies |
|---|---|---|
| Render Resolution | Original (640×480), 2× (1280×960), 3× (1920×1440), 4× (2560×1920) | At the next Start Game |
| Anti-Aliasing | Off, FXAA | Immediately |
| Aspect Ratio | Original 4:3, Widescreen 16:9 | Immediately |
| Field of View | 60° (Original), 70°, 80° | Immediately |

The game draws into a borderless window at the device's native resolution, and
the picture is fitted inside the screen's safe area. On a 4:3 iPad the original
aspect fills the screen; on wider screens 4:3 is pillarboxed and 16:9 uses the
game's own widescreen mode. Movies are the original 640×480 videos and are
scaled, not re-rendered.

What to know about resolution today:

- **Render Resolution changes take effect at the next start.** Stop the game and
  start it again after changing it.
- **The picture shrinking after the touch editor is fixed but awaiting device
  confirmation.** Earlier builds could shrink the game into the bottom-left
  corner after saving a touch layout. 0.2.0 locks the game window to landscape
  and re-aligns it whenever NightPad's menus close. If it happens again, Stop
  and Start the game and [report it](https://github.com/chrissotraidis/nightpad/issues).
- **3× and 4× have not been measured over long sessions.** They look right on
  an iPad Pro 12.9-inch (M2), but heat, battery use and frame pacing over an
  hour of play are unmeasured. Older devices and iPhones may need 2× or
  Original.
- **Not every combination has been checked.** Scoped weapons at every field
  of view, the driving HUD in 16:9 and notched phone screens have simulator
  evidence, not full device coverage.
- **High-resolution texture packs are not supported.** A `textures` folder
  does nothing yet.

## Cheats

**⋯ → Cheats** uses the game's own cheat switches. Everything is off by default:

- **Immortality** and **Unlimited Ammo** take effect during play.
- **All Weapons** gives every weapon and gadget from the next mission start.
- **Unlock All Content** opens every mission, difficulty and multiplayer option
  without changing your saves; turning it off hands back what you had earned.

Cheats do not apply to driving missions. The game's original Secret Unlocks and
multiplayer rules stay in its own menus.

## Saves and game data

- **⋯ → Data & Saves → Data & Save Status…** shows whether game data is ready
  and lists your saves.
- **Game Data** imports the prepared folder with the file picker, or from the
  app's **NightPad Import** folder in Files with **Import from NightPad
  Folder**. Importing never touches your saves. After a re-import, **Remove
  Previous Game Data** frees the old copy for that session.
- **Saves** shares your saves as a backup, imports a backup, or restores from
  the app's **Save Import** folder. Restoring asks before replacing a save with
  the same name and is available while the game is stopped.

Saves are written as a complete new file with a backup of the previous copy,
so an interrupted save keeps the last complete one.

## Testing status

NightPad separates what has been played on hardware from what has been checked
in the Simulator or by automated tests.

| Area | Where | Result |
|---|---|---|
| Launch, original menus, Start/Stop, ⋯ menu | iPad Pro 12.9-inch (6th generation), iPadOS 27.0.1 | Played by the maintainer |
| Display and render resolution up to 4× | Same iPad | Confirmed by the maintainer |
| Touch controls and an Xbox controller | Same iPad | Confirmed by the maintainer |
| Level audio across missions and restarts | Same iPad | Confirmed by the maintainer |
| 0.2.0 fixes: post-editor display, ⋯ menu audio hold, All Weapons and Unlock All in play, Nightfire default with RB weapon switching | Same iPad | Installed; awaiting the maintainer's play check |
| Paris tutorial, the Exchange, driving handoffs, local bot matches | iPhone and iPad Simulators (iOS 26.5 and 27) | Pass |
| Repeated Start/Stop, action ↔ driving transitions, Stop during a movie | Simulator and Mac engine tests | Pass |
| Complete campaign and earned mission saves | Not yet | Open |
| iPhone hardware | Not yet | Open |
| Four players with real controllers | Not yet | Open |
| Long sessions, heat and battery at 2× to 4× | Not yet | Open |

Automated checks, all passing on 0.2.0:

- `scripts/verify_quick.sh`: host tests for input, touch layout and input,
  settings, presentation, contrast, data import, diagnostics and saves, both
  iOS build lanes, the link check, the privacy check and patch reconstruction.
- `scripts/verify_engine.sh`: 13 gates that run the real engines built for
  Mac, covering action and driving boot and lifecycle, pauses and pause
  clocks, Stop during a driving movie and at early points, cheats, secret
  unlocks, and engine transitions, handoffs and round trips.
- **PadMint player check:** a fresh clone built the way a player's PadMint
  builds it, with Apple's Python 3.9 and an empty PadMint folder, producing the
  IPA and the game data folder from the disc image.

Eleven recorded action sessions replay unchanged over 208,364 frames. That is
regression evidence, not a full campaign completion. The detailed record is in
[STATUS](docs/STATUS.md) and the [test matrix](docs/TEST-MATRIX.md).

## Known issues

- **Campaign completion is unverified.** Missions start, fail and replay
  correctly, but no complete mission-results save has been earned in testing.
- **Spatial audio is simpler than the Xbox.** The SDL audio backend mixes 3D
  sounds with distance and panning, without the Xbox's HRTF and I3DL2 reverb.
- **Discs with only the 30 fps movie set lack some movies.** NightPad runs them
  in NTSC mode. The attract trailer is missing from that set, so a boot that
  opens the attract page shows black until you press A, and one PAL ending
  movie is unavailable.
- **The post-editor display fix, All Weapons, Unlock All Content and RB weapon
  switching** are new in 0.2.0 and still need a device play check.
- **Older codenames keep Classic Bond** until changed in Controller Setup.
- **Texture replacement is not implemented.**
- **No online or LAN play.**
- **Power loss during a save** is covered by host tests only.

The full list, with causes and evidence, is in [KNOWN-ISSUES](docs/KNOWN-ISSUES.md).

## Refinement plan

The focus is stability of the original game on device. In order:

1. **Confirm the 0.2.0 fixes on the iPad:** the picture after saving a touch
   layout, audio held under the ⋯ menu, All Weapons and Unlock All in a
   mission, and RB weapon switching on a new codename.
2. **Play the campaign through** on device, earning and reloading mission
   saves, including every driving mission.
3. **Test iPhone hardware** and tune the phone touch layout.
4. **Measure long sessions** at 2×, 3× and 4× for heat, battery and frame
   pacing, and recommend a default for each class of device.
5. **Split screen with up to four real controllers**, including reconnects and
   rumble.
6. **Audio fidelity:** reverb and positional audio closer to the Xbox.
7. **Movie sets:** support PAL 25 fps discs and confirm other dumps.
8. **Texture replacement** for high-resolution packs.
9. **Online play** stays deferred until the game is stable. The research and a
   peer-to-peer plan are in [NETPLAY-PLAN](docs/NETPLAY-PLAN.md).

## Frequently asked questions

### Is NightPad an emulator or a streaming app?

No. The upstream project rebuilt the Xbox game's code as ordinary C and C++,
and NightPad compiles it for iPhone and iPad. Only the game's data comes from
the disc. It needs no JIT and no connection to a Mac while playing.

### Where is the IPA download?

There isn't one. NightPad distributes source, a PadMint recipe and checksums.
Build your own copy on a Mac with [the steps above](#get-nightpad).

### Can I use the PC or PlayStation 2 version?

No. Only the original Xbox disc works.

### Why does PadMint need my disc during the build?

The app imports a prepared, checked game data folder rather than a raw disc
image. PadMint extracts that folder from your disc next to the IPA, so the app
never has to read an ISO on the device.

### Does multiplayer work?

Split-screen matches with bots work, with touch for player 1 and up to four
controllers. Four real controllers at once have not been tested yet. There is
no online play.

### Does everything work?

This is a preview. The game plays on an iPad Pro, but the full campaign, iPhone
hardware, long sessions and four-controller play remain open. See
[Testing status](#testing-status).

## Help and community

Use **⋯ → Help & Feedback → Diagnostics** to prepare a log; review it before you
share it, because nothing uploads automatically. **About NightPad** links to
this repository and its issues. Include your device, iOS version, NightPad
version and the steps to reproduce the problem. Never attach disc images,
extracted game files, saves or signing files.

[GitHub issues](https://github.com/chrissotraidis/nightpad/issues) ·
[Discord community](https://discord.gg/xwHfUD2bxW)

## For developers

The iPhone Simulator runs the real game, which makes it the fastest place to
work:

```sh
scripts/bootstrap_dependencies.sh
python3 scripts/prepare_game_data.py --iso /absolute/path/to/your-nightfire.iso
scripts/build_ffmpeg_ios.sh simulator
scripts/build_ios_engines.sh simulator
scripts/build_ios_shell.sh simulator
xcrun simctl install <SIMULATOR_UDID> build/ios-shell-simulator/Debug-iphonesimulator/NightPadShell.app
xcrun simctl launch <SIMULATOR_UDID> com.chrissotraidis.nightpad
```

Keep one simulator booted at a time for this project's tests. The Simulator
presents the Mac keyboard as a gamepad once a game starts, so turn on **⋯ →
Controls → Touch Controls → Always Show** to see the touch overlay. Simulator
rendering is development evidence, not device acceptance.

```sh
scripts/verify_quick.sh    # host tests, both iOS lanes, links, privacy, patches
scripts/verify_engine.sh   # the slower real-engine suite on Mac
```

Engine changes live in [patches/](patches/) as a numbered series (46 patches
across 87 files in 0.2.0), applied to the pinned upstream commit.
[UPSTREAM-DELTA](docs/UPSTREAM-DELTA.md) explains each one.

## Project map

| Path | Purpose |
|---|---|
| [`apple/ios/`](apple/ios/) | The Apple shell: menus, touch controls, layout editor, import, saves |
| [`apple/shared/`](apple/shared/) | Shared host code, including game data import |
| [`patches/`](patches/) | Numbered patches applied to the pinned engine |
| [`scripts/`](scripts/) | Bootstrap, builds, packaging, data preparation and tests |
| [`padmint.json`](padmint.json) | PadMint build recipe |
| [STATUS](docs/STATUS.md) | Current progress and verification record |
| [TEST-MATRIX](docs/TEST-MATRIX.md) | Evidence for each test area |
| [KNOWN-ISSUES](docs/KNOWN-ISSUES.md) | Open issues with causes and evidence |
| [DEVICE-HANDOFF](docs/DEVICE-HANDOFF.md) | Signing, installation and the device checklist |
| [CONTROL-SCHEMES](docs/CONTROL-SCHEMES.md) | Every on-foot control scheme |
| [NETPLAY-PLAN](docs/NETPLAY-PLAN.md) | Deferred online play research and plan |
| [UPSTREAM-DELTA](docs/UPSTREAM-DELTA.md) | What NightPad changes in the engine |
| [PROVENANCE](docs/PROVENANCE.md) | Sources, licences and the data boundary |

## Research and credits

NightPad builds on [nightfire-cxbx](https://github.com/NightfireResearch/nightfire-cxbx)
by NightfireResearch, itself based on MattKC's
[Reburn3](https://github.com/reburndev/reburn3). The Apple shell follows
[GalaxyPad](https://github.com/chrissotraidis/galaxypad) for its menus and
layout editor and [SunPad](https://github.com/chrissotraidis/sunpad) for
dual-stick input. [extract-xiso](https://github.com/XboxDev/extract-xiso)
reads the disc image, and SDL 3, FFmpeg and SPIRV-Cross supply the platform,
movie and shader support. Exact revisions are pinned in
[`config/dependencies.lock.json`](config/dependencies.lock.json).

## Legal and provenance

NightPad is an unofficial fan project. It is not affiliated with or endorsed by
Eurocom, Electronic Arts, Danjaq, Metro-Goldwyn-Mayer, Eon Productions or
Microsoft. 007, James Bond, Nightfire and related names, characters and game
content belong to their respective owners.

No game data, disc image, movie or save is included or distributed. You must
supply data from your own copy of the original Xbox game.

The upstream nightfire-cxbx repository does not publish a licence. NightPad
pins it by commit and keeps its own engine changes as patches. The reused
GalaxyPad and SunPad files are GPL-3.0 and keep their notices. Details are in
[PROVENANCE](docs/PROVENANCE.md).
