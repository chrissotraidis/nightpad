# Decision 0009: one controller authority, one touch mapper

Date: 2026-10-27

## Result

NightPad treats Apple's GameController framework as the only physical
controller authority while the native shell is running. SDL still owns the
window, keyboard and mouse, but its gamepad reads are bypassed: the engine asks
the host for each port's state instead of opening SDL gamepads of its own. This
keeps one controller from reaching the game twice through two independent
stacks.

The shell publishes four XInput-shaped ports at 60 Hz. Port 0 is the touch
player's port; a physical controller in player slot 1 merges into the same port
so a solo player keeps player one whether they use touch, a controller or both.
Further controllers take slots 2-4. Slot reconciliation is session local: a
controller that stays connected keeps its slot through foreground resume, a new
controller fills a free slot, and a sole returning controller reclaims player
one.

Touch samples are mapped from the authored layout rather than from per-widget
state. One finger per control becomes a stick vector, an eight-way D-pad
direction, a digital button or an analog trigger depth, and several fingers can
move, look, fire and aim at once. The mapping lives in shared C++ so the same
rules run in tests and on device.

Modern LB/RB carry the original White/Black bits, triggers stay analog, Start
and Back keep their original meaning, and the donor's native-pause shortcut is
not reused. Rumble requests return through the port that produced them and are
cleared when play is suspended or a controller leaves; a controller joining is
required to release its buttons before its input is accepted.

## Evidence

- `scripts/test_input.sh` covers four ports, short taps across polling
  boundaries, dead zones, trigger thresholds, source merging, release before
  reacquire and port isolation.
- `scripts/test_touch_input.sh` covers sticks, eight-way D-pad, analog trigger
  depth, shoulder/system bits, five simultaneous touches and the newest finger
  winning a shared control.
- `scripts/test_controller_slots.sh` covers first assignment, stable slots
  across resume, holes left by a leaving second player, reclaiming player one,
  duplicate enumeration and the four-player cap.
- Both shell lanes build; the device link exports the host-pad and rumble
  bridge. The iPhone 17 simulator renders the overlay and the native
  three-dot menu.

## Limits

Physical controller connect/reconnect, rumble feel and multi-finger ergonomics
still need device evidence. Controller button remapping (the game's own eight
schemes) and vehicle/POV contextual layouts are engine work that has not
started.
