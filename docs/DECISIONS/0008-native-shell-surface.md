# Decision 0008: native shell surface

Date: 2026-10-27

## Decision

NightPad has its own landscape UIKit shell rather than embedding GalaxyPad's
full Nintendo-oriented overlay. The shell keeps a persistent three-dot button
and owns the native surfaces NightPad needs:

- a menu with Start Game, Game Data & Saves, App Pause, About NightPad and
  Diagnostics;
- a data panel that reports missing/ready/recoverable state, imports a prepared
  folder through the files picker, shows import progress, cancels an import, and
  removes retained previous data;
- a native app-pause card with an explicit Back to Game action;
- an About card naming the engine and interface donors;
- a diagnostics share entry for the app-owned diagnostics directory.

The panel is a UIKit overlay in the same window, not a second window: this keeps
orientation, accessibility and menu reachability under one view controller while
the engine host is attached beneath it later. The three-dot button always
remains above game content.

The shell uses the tested `NightPadPaths` and `GameDataImporter` core. Import
activation currently passes `runtimeStopped = true` because the engine host is
not attached yet; the coordinator must pass its actual stopped state when it is.

## Evidence

- `scripts/build_ios_shell.sh simulator` and `device` both build the
  `NightPadShell` app.
- Simulator screenshots show the home state, open three-dot menu and data panel;
  they are stored under ignored `evidence/ios-shell/`.
- The app uses a landscape-only full-screen scene and exposes its Documents
  directory to Files for prepared-folder imports.

## Remaining

Attach the combined engine host, pass real pause/stopped state into import and
menu gating, clear input while native UI is open, and exercise the picker/progress
flow end to end on device.
