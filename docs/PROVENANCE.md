# Provenance and data boundary

NightPad reuses the reconstructed engine from
`NightfireResearch/nightfire-cxbx`, the Apple overlay/host mechanisms from
`chrissotraidis/galaxypad`, and selected input mechanisms from
`chrissotraidis/sunpad`. Exact commits are pinned in
`config/dependencies.lock.json`; donor checkouts are read-only references and
are not runtime dependencies.

The upstream engine repository contains no reviewed first-party root license
file. Its provenance and any later distribution decision remain separate from
private-candidate testing. Reused GalaxyPad and SunPad files retain their
notices and are recorded in `docs/UPSTREAM-DELTA.md`.

The original Xbox image and extracted data are owner-supplied private inputs.
They, generated binaries, saves, captures, credentials and signing artifacts are
outside the source commit. `prepare_game_data.py` preserves the source image,
validates member paths and only activates a content-addressed extracted tree
after a complete listing/tree comparison.

The app contains no networking APIs: diagnostics are written locally and shared
only through the system sheet, and the About page's links open in the user's
browser. `scripts/check_privacy.sh` fails if `URLSession`, `NSURLConnection`,
`CFStream`, `NWConnection`, `getaddrinfo` or a socket call appears in `apple/`.

This document records provenance; it is not a legal conclusion or a public
distribution approval.

