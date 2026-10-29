# Decision 0017: fit presentation and preserve engine contracts

Date: 2026-10-28

Patch 0030 changes only the SDL GPU presentation copy. It fits the selected
4:3 or 16:9 aspect inside the window's safe area, converts logical safe-area
coordinates to drawable pixels with inward rounding, centers the result and
clears the swapchain attachment to opaque black. The selected display aspect
is independent of RenderWidth/RenderHeight: the Xbox can render anamorphic
widescreen into a 640x480 buffer. The setting is read at device creation for
each engine session. Resizing queries the current drawable and safe area on
the window thread. Offscreen rendering and frame readbacks retain their
existing paths.

The pure geometry test covers both aspects, phone/tablet/portrait shapes,
safe-area conversion, odd dimensions, minimized windows and large dimensions.
Metal simulator captures show action titles in both aspects on phone and
tablet, the phone driving HUD in 16:9, and tablet driving in both aspects.
Touch controls keep their existing safe-area canvas and respond to input.

The tablet scope exposed a second defect. The driving kernel returned the
widescreen flag as raw bit 0 of XC_VIDEO. The actual `Xbox_XGetVideoFlags`
consumer shifts that dashboard value right by 16, so the renderer still saw
4:3 while presentation used 16:9. Patch 0031 returns bit 16. The settings test
now links the real kernel adapter, XAPI getter and POSIX profile reader, as
well as the action parser. It tests both initial choices and an opposite
choice after rewriting the file. The test fails before the fix and passes
after it. On the rebuilt tablet app, the previously oval driving scope is
circular in 16:9. The original scope and cinematic behavior still need the
broader gameplay/device matrix; this evidence does not pass all of R18.

The replay check also caught an older regression. Patch 0023 had changed
every missing background movie to finish immediately, in addition to fixing
the missing attract trailer. CastleIndoors1 then stopped at frame 2 because
input no longer lined up. A build with the old presentation backend failed
identically. Patch 0032 removes that generic early completion while retaining
the specific `P_ATTRACT_Handler` recovery. The unchanged recording then
matches all 635 frames. The complete available eleven-recording corpus is
being rechecked; its result must be recorded separately when it terminates.
No recording, checksum, assertion or golden was changed.

Evidence is private under `evidence/presentation-fit/`,
`build/tests/presentation/` and the timestamped `evidence/action-demos/` runs.
Both iOS build lanes, unsigned Release packaging, patch reconstruction and
the final three action/one driving native lifecycle cycles pass. Physical
device acceptance, sustained performance, action scope/FOV combinations and
the full campaign remain open.
