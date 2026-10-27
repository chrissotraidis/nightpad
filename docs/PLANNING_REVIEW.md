# NightPad planning review

**Date:** 27 October 2026  
**Scope:** Planning documents and primary-source research only.  
**Outcome:** PRD and goal-loop packet prepared; implementation remains unstarted.

## Reviews completed

Three independent research/review streams examined the reconstructed Xbox engine and iOS portability, Chris's GalaxyPad/SunPad interface donors, and enhancements/local/online multiplayer. Review findings were incorporated into the final documents. These were source/document reviews, not builds, UI inspections or gameplay sessions.

| Finding | Final planning change |
| --- | --- |
| The native preset is macos-arm64; macos is a Windows cross-build | Verified native recipe and a warning against the misleading preset |
| Current action demo inventory has 12 recordings, not the older documented 13 | Pin-specific inventory of 12 and 221,759 frames; future executor discovers and hashes actual files |
| Galaxy's controller ownership is single-player | New explicit Xbox per-port adapter; P2 cannot steal or hide touch P1; input/rumble isolation tests |
| View/Select is consumed by Galaxy's app-pause shortcut | Explicit removal because Xbox Back is needed for Nightfire night vision/menu behavior |
| Five-touch correctness can pass despite poor ergonomics | Separate sustained combat usability gate and layout/rotation recovery tests |
| A platform pointer probe is narrower than R06 | G03 provides preliminary evidence; G04 owns final R06 transition/restart acceptance, rechecked later |
| Extraction must be bounded before files are written | Pre-extraction path/extent checks or equivalent reviewed containment, then post-extraction validation |
| Two multiplayer matches do not cover every original mode | Every map/scenario inventory and smoke/scoring-family coverage, plus complete representative matches |
| A connection test is not netplay acceptance | Two physical clients, complete match plus 15 minutes per supported profile, latency/stall budget and interruption recovery |
| Render/audio feedback influence replay behavior | Determinism/divergence experiments before netcode selection; enhancement tests separate from recorded-config replays |
| Existing Windows texture replacements do not imply Metal support | Bounded SDL/Metal prototype and an honest adoption/deferral decision |
| Positive optional-feature feasibility can otherwise end in an unfinished plan | Selected feasible scope must be implemented and tested; deferral requires a concrete measured blocker |

## Structural checks performed on this packet

- All three JSON planning files parse.
- The goal graph has 14 unique goals, known dependencies and no cycles.
- All 30 requirements have valid goal owners: 26 Core, 3 Decision, 1 Conditional.
- Markdown goal dependencies and requirement IDs agree with the machine-readable plan.
- R06 is owned by G04, preventing premature completion after the standalone iOS probe.
- All template goals are pending; all requirements are unverified; completed_tests is empty.
- Seven research repositories/dependencies have full 40-character revision pins.
- All 26 cited source IDs exist in SOURCES.md.
- Local document links resolve, Markdown code fences are balanced, and the packet contains only planning text/JSON/checksums.
- Archive contents and file checksums were checked after packaging.

These checks establish document consistency. They do not establish that NightPad builds, that the supplied ISO is compatible, that signing/device access exists, or that gameplay works.

## Evidence boundaries

No NightPad repository was created. No source fork was modified. No prerequisites were installed for NightPad, no ISO was accessed/extracted, and no game build, deployment, performance measurement or gameplay test was run. The packet contains no retail data, donor source code, executables, credentials or personal saves.

The planned execution target is a tested private candidate. The future agent must establish the actual image identity, iOS memory/linker behavior, signed physical-device compatibility, full campaign transitions, control usability, persistence and the viable enhancement/network scope before claiming completion.

