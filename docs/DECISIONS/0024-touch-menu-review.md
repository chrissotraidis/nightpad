# Decision 0024: touch geometry and menu hierarchy review

Date: 2026-10-29

The owner requested a screenshot-based review of awkward touch placement and
inconsistent three-dot navigation. Fresh phone captures showed a diagonal,
unequal face-button arrangement, an oversized D-pad, scattered system keys,
and a Controls menu mixing touch editing, controller preferences and app pause.
The pinned GalaxyPad root groups play settings first and places Stop last;
NightPad now follows that hierarchy with Xbox-specific controls.

The root contains Display, Controls, Enhancements, Data & Saves, Help &
Feedback, and Start/Stop Game last. Controls separates Touch Controls from
Controller and keeps a short Control Guide entry. Touch Controls contains
Edit Layout, Always Show, and Auto-Hide with its controller subtitle. The
manual override visibly disables Auto-Hide while it takes precedence. Data
and save actions have distinct submenus. Native menu entry already pauses
local gameplay/audio; Xbox Start remains the original pause action. The old
App Pause card remains a diagnostic entry point, not a Controls row. Native
Audio/master volume is still outstanding PRD work and is not represented by
an inert menu item.

Phone and tablet defaults use aligned movement/look sticks, an equal-sized
Xbox A/B/X/Y diamond, secondary keys above it, and a separate Start/Back row.
Tablet placement was revised again after real gameplay showed health/ammo
occlusion in the first proposal. Existing version-3 custom files remain
valid. Reset opts into the new defaults; Save makes that choice persistent.

The review also found behavioral geometry defects. The live canvas applied
safe-area margins twice. Round controls were drawn smaller than the input
rectangles used for stick range and hit testing. Visual feedback used parent
coordinates in a control's local space. The editor had a shorter canvas and
mutated the model while opening it. One nonmutating `ForCanvas` resolver now
supplies drawing, input and editor rectangles, retaining a 44-point minimum
and center-preserving square controls. The full-screen editor uses the same
safe-area canvas and keeps Save, Cancel and Reset above it.

Focused host tests cover minimum targets, bounds, square geometry,
non-overlap at representative landscape sizes, diamond order, nonmutating
resolution and existing persistence/error cases. Simulator review covers the
root and submenus, editor Save/Cancel/Reset, and original frontend/gameplay
input. Private before/after captures and the exact tested artifact identity
are indexed in `evidence/touch-menu-audit/result.json`. Physical grip,
simultaneous fingers, drag/pinch acceptance and larger-text revalidation of
the redesigned editor remain open; prior screenshots do not prove those new
paths. Campaign completion and device acceptance are separate gates.

No engine source or numbered portability patch changed in this pass.
