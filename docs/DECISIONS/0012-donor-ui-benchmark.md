# Decision 0012: donor UI is the quality bar

Date: 2026-10-27

## Decision

The pinned SunPad and GalaxyPad checkouts are the reference for what a finished
NightPad surface looks like. New native UI is compared against them before it
is called done, and NightPad may copy their shape freely while keeping the
engine and data adapters its own.

- The three-dot menu follows SunPad: a translucent capsule button with a bold
  ellipsis, a native `UIMenu` that shows as the button's primary action, and
  grouped submenus instead of a flat list. NightPad keeps SunPad's Display and
  Game Data & Saves grouping and adds Game, Assists and Info.
- Settings surfaces follow SunPad's pattern of a menu item that opens a focused
  panel, with toggles carrying their state in the menu itself.
- Touch editing follows GalaxyPad's interaction model - drag a control, tap it
  to resize, reset when it goes wrong - while NightPad keeps its editor in a
  sheet so the layout can be exported and reverted explicitly.
- Control help follows the donor habit of a plain reference page rather than
  remapping screens, because the game's own eight schemes stay authoritative.

Deliberate differences: NightPad has no controller remapping UI (the game owns
the schemes), no Nintendo-specific settings, and its diagnostics are a
reviewable local report rather than a GitHub issue prompt.

## Evidence

- `references/sunpad/apple/ios/SunPadGameOverlay.mm`: menu button styling,
  `buildMenu`, submenu grouping and item state.
- `references/galaxypad/apple/ios/GalaxyPadGameOverlay.mm`: editor bar,
  drag/resize hint, size slider and Done action.
- `apple/ios/NightPadShellViewController.mm` and
  `apple/ios/NightPadTouchLayoutViewController.mm` implement the NightPad
  versions and pass the simulator smoke checks in `docs/TEST-MATRIX.md`.

## Remaining

Physical ergonomics on phone and tablet still decide whether the touch sizes
and menu reach are good enough; that check needs a device.
