# NightPad planning packet

**Prepared 27 October 2026. Planning only: no NightPad implementation, build, extraction or deployment has been started.**

## Read first

The selected product is the original **Xbox 007: Nightfire** running natively on iPhone and iPad, built from `NightfireResearch/nightfire-cxbx`. GalaxyPad supplies the primary native menu/touch/editor reference; SunPad supplies secondary dual-stick/input patterns. The owner's Xbox ISO will be in the future project's `ref/` or `REF/` folder.

## Packet contents

| File | Use |
| --- | --- |
| [NIGHTPAD_PRD.md](NIGHTPAD_PRD.md) | Product scope, 30 requirements, architecture, controls, enhancement/network decisions, acceptance matrix |
| [NIGHTPAD_GOAL_LOOP.md](NIGHTPAD_GOAL_LOOP.md) | Autonomous procedure, 14 goal cards, verified desktop recipes, blocker/recovery rules and completion predicate |
| [goal_plan.json](goal_plan.json) | Goal dependencies, requirement ownership, policies and terminal-state rules |
| [execution_state.template.json](execution_state.template.json) | Unstarted state template for the later implementing agent |
| [sources.lock.json](sources.lock.json) | Seven audited source/dependency pins; no retail content or fabricated image hashes |
| [SOURCES.md](SOURCES.md) | Primary-source bibliography, evidence limits and important corrections |
| [PLANNING_REVIEW.md](PLANNING_REVIEW.md) | Planning review scope and corrections; no gameplay-test claims |

The Markdown documents define the behavior and acceptance gates. JSON indexes the same plan; it cannot weaken a requirement. Copy these documents into the eventual implementation repository's documentation area while preserving their relative links. Create implementation state from the template only when execution is explicitly requested.

## What to hand to the implementing agent

The following prompt is intended for a later execution request. It is **not** an instruction to start implementation during a planning-only review.

> Build NightPad according to the attached NIGHTPAD_PRD.md and NIGHTPAD_GOAL_LOOP.md. Start at G00 and continue autonomously through the goal loop. The original Xbox Nightfire ISO is in the designated project's ref/ or REF/ directory. Use the exact research source pins initially, download/build necessary public prerequisites, and use the pinned GalaxyPad/SunPad repositories for the native UI and Xbox-adapted touch controls. Preserve existing work and original data. Implement, build, diagnose and test the complete game, including action/driving transitions, saves, audio, controls and local multiplayer. Complete the cheats/mods/network feasibility tracks and finish any features their evidence supports. Do not ask for routine milestone permission. Record evidence and resume state after each meaningful iteration. If hardware, signing, data or another real dependency blocks a gate, complete independent work and give the smallest concrete handoff. Stop only when the private-candidate completion predicate passes or a documented blocker remains after the unblocking procedure. Do not publicly publish, buy services, download retail game data, or send messages under this instruction.

## Decisions already made

- Xbox reconstruction is fixed; do not switch to PC/GoldSrc, Source, PS2, emulation or XBE recompilation.
- The first engine baseline is native `macos-arm64`; the preset named `macos` builds Windows executables.
- First iOS risks are the encoded-pointer/linker layout, real Metal/media support, and moving action/driving handoffs into one process.
- Xbox defaults include Y jump, A crouch and Back night vision. Remove Galaxy's conflicting View/Select app-pause shortcut.
- Galaxy's controller donor is single-player. Multiport input and per-player touch visibility are new NightPad work.
- Full campaign and required physical iPhone/iPad evidence are mandatory. Simulator or a title screen cannot close the project.
- Higher-resolution rendering and original unlocks are core. New debug-cheat/texture/netplay work has explicit feasibility and adoption gates.
- A feasible optional feature must be implemented and tested within its selected scope. A failed experiment may support a specific deferral; an uninvestigated idea may not.
- The final artifact is a tested private candidate with a reproducible build/data/signing handoff. Publication is separate.

## Still to establish during execution

Actual ISO identity/region; exact accessible Mac/Xcode/signing/device environment; iOS pointer and shader behavior; complete engine reset boundaries; phone/tablet performance limits; driving/POV definitions from retail data; and the viable netplay architecture. These are recorded unknowns, not questions that must delay all useful work.

