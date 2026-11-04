# Action control schemes

Status: **source-mapped**. The game ships eight on-foot controller schemes.
NightPad sends raw Xbox pad state, so the engine applies whichever scheme the
player picked in the original Controller Setup page. The touch overlay also
emits Xbox buttons, so the scheme applies to it unchanged. None of this is
validated on hardware yet.

Source: `src/action/engine/psiInput.cpp`, the `switch(playerInputs[i].controlStyle)`
block, which fills 19 action channels per scheme. The scheme names come from
`docs/ui/handlers.md` (labels on the Controller Setup page).

## Baseline: Nightfire

NightPad changes two things about this scheme (patch 0046): new codenames
start on it (the original defaulted to Classic Bond), and RB (Black) changes
weapon instead of gadget, so the bumper beside the right trigger switches
weapons as on a modern pad. Gadgets stay on the D-pad. Existing codenames keep
their saved scheme until it is changed in the game's Controller Setup.

| Input | Action |
| --- | --- |
| Left stick | Move |
| Right stick | Look and aim; turret aim |
| RT / LT | Fire / scope zoom |
| Y / A | Jump / crouch |
| X | Reload |
| LB | Alternate fire |
| D-pad right, B or RB | Next weapon |
| D-pad left | Previous weapon |
| D-pad up | Next gadget |
| D-pad down | Previous gadget |
| D-pad up / down | Zoom in / out |
| Back | Night vision |

Every other scheme below is the same except where listed.

## Moonraker

- Crouch moves to B; reload moves to A.
- Next weapon is D-pad right or X.
- Next gadget is RB only; there is no previous gadget binding.

## Octopussy

Look and aim are swapped horizontally (left stick looks, right stick moves);
vertical axes stay as they were.

- Crouch B, reload A, next weapon D-pad right or X, next gadget RB only, no
  previous gadget.

## Goldfinger

- Crouch X, reload A.
- Alternate fire moves from LB to B.
- Next weapon is D-pad right only; next gadget is D-pad up only.
- Night vision moves from Back to LB or RB.

## Dr. No

Fully southpaw: the right stick moves and aims, the left stick looks; turret
aim follows the same swap.

- Zoom in / out move from the D-pad to Y / X.
- Jump is D-pad up, crouch is D-pad down.
- Reload A, alternate fire B.
- Previous / next weapon are LB / RB; previous / next gadget are X / Y.
- Night vision is D-pad left or right.

## Thunderball

Look and aim are swapped horizontally, including turret aim.

- Crouch X, reload A, alternate fire B.
- Next weapon D-pad right; next gadget D-pad up.
- Night vision LB or RB.

## GoldenEye

- Crouch X, reload A.
- Alternate fire moves from LB to RB.
- Weapons cycle on the D-pad: down (or B) next, up previous.
- Gadgets cycle on the D-pad right / left instead of up / down or RB.
- Night vision is LB.

## Classic Bond

Look and aim are swapped horizontally, including turret aim, like Thunderball.

- Crouch X, reload A, alternate fire RB.
- Weapons: down (or B) next, up previous.
- Gadgets: right next, left previous.
- Night vision LB.

## What NightPad must keep

- The scheme belongs to the engine state, not to the app. NightPad never
  rewrites it, and the help page describes Xbox buttons rather than a scheme.
- The touch layout and a physical pad feed the same four ports, so both follow
  the selected scheme; only the stick geometry differs.
- Device validation still needs one pass per scheme for movement, aim, weapon
  and gadget cycling, and night vision.
