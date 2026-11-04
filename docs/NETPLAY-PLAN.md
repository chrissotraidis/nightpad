# Online multiplayer plan (deferred)

Status: **research and plan only**. Nothing here is implemented or scheduled.
Stability of the original build comes first. Decision 0011 still defers
netplay; this document records how it would be built when it is picked up.

## What exists elsewhere

- **Xbox, PS2 and GameCube (Eurocom):** the versions NightPad runs never had
  online play or System Link. Multiplayer is local split screen for up to four
  players plus bots. XLink Kai (LAN/System Link tunnelling) and Insignia
  (revived Xbox Live) therefore have nothing to connect for this game.
- **PC (Gearbox, Half-Life engine):** a different game with its own
  multiplayer. It shipped online play; after GameSpy closed in 2014 the
  community kept it running with the unofficial 5.91 patch, the OpenSpy master
  server and direct-IP joins (nightfirepc.com, PCGamingWiki). Nightfire Open is
  a separate open-source rebuild of that PC game. None of it applies to the
  Eurocom engine.
- **GameCube emulation (Dolphin):** Dolphin netplay can run a console game's
  local multiplayer online by running the game on every machine and exchanging
  controller input. Whether Nightfire has been played this way was not
  confirmed. It is the same model proposed below.

No native online build of the Eurocom Nightfire is known.

## Why NightPad can do it

The action engine already has a deterministic input-replay mode (the time
demos, `src/action/devtools/Demo.h`):

- the game clock follows frames, not wall time;
- disc reads finish as they are issued;
- sound-device answers (status and play cursors) are recorded and returned;
- per-port pad polls are the only input;
- frame checksums detect a divergence.

Eleven unchanged recordings replay 208,364 frames exactly, and repeated
headless Mission 1 runs give byte-identical sound traces. That is the
foundation for **deterministic lockstep**: every device runs the same
four-player match and only controller input crosses the network.

## Design: input lockstep

1. **Session.** All peers run the same NightPad build and the same game data
   (the prepared data already has an identity hash). The host picks map, mode,
   rules, bots and cheats; the session start message carries them, plus the
   display settings that can affect simulation (widescreen, FOV) and a seed
   if one is needed. Every peer boots straight into the match on the frame
   clock.
2. **Ports.** Each peer owns one of the four pad ports. Bots are simulated
   identically everywhere and need no traffic.
3. **Frames.** Each peer sends its port's pad for frame N + D, where D is an
   input delay of 2-4 frames (33-67 ms at 60 fps). Frame N runs only when all
   four ports' inputs for N are present; otherwise the peer waits. Packets
   repeat the last few frames' inputs so a lost datagram costs nothing.
4. **Desync check.** Every 60-120 frames peers exchange a checksum of game
   state (the demo system's existing checksums). A mismatch ends the match
   with a report naming the frame, rather than letting it drift.
5. **View.** First milestone: every peer shows the normal split screen.
   Second: each peer draws only its own player full screen, which needs an
   engine change to render one viewport.
6. **Native menu.** During a match the ⋯ menu must not pause the simulation
   alone: either it pauses every peer, or it opens without pausing.
7. **Disconnects.** A peer that stops sending is shown as waiting; after a
   timeout the match ends cleanly for everyone. Rejoining mid-match is out of
   scope (it would need state transfer).

### Transport

- **Game Center real-time matches (GKMatch):** invites, matchmaking, NAT
  traversal and relay for up to four players, with no server to run. The
  natural first choice on iPhone and iPad.
- **Network framework (UDP):** for local-network play and testing without
  Game Center.

Either adds the first network path to the app. `scripts/check_privacy.sh`
rejects networking APIs today, so netplay needs a deliberate, documented
exception limited to the netplay module.

### Alternatives considered

- **Rollback (GGPO style):** hides latency better but needs fast save and
  restore of the whole game state (the engine's heap window). Possible later,
  after lockstep works.
- **Host streams video:** the host runs split screen and streams it. Simple,
  but high bandwidth and latency, and each player still sees the split.
- **Emulating System Link/XNet:** the game never had it; there is no protocol
  to emulate.

## Risks and unknowns

- Determinism across separate devices and runs has not been shown. The
  replay evidence is one process replaying its own recording.
- Wall-clock reads outside the demo clock (two rdtsc sites remain in the
  image), thread timing in file and sound workers, and uninitialised memory
  could each cause drift.
- Display settings may change simulation (camera or FOV feeding aim); lock
  them to the host's values.
- Rendering a single viewport must not change game state.
- The action engine's driving handoff: multiplayer maps are action-only, so a
  match must never leave for the driving engine.

## Phases

| Phase | Work | Exit criterion |
| --- | --- | --- |
| 0 | Two action engines on one Mac, frame clock, inputs exchanged in memory, bot match | Checksums match for a full timed match on two maps |
| 1 | Same over UDP between two Macs, then iPad and Mac | No desync in ten matches; input delay stays at D |
| 2 | Split-screen netplay on two iPads with Game Center invites | Four-port match with two humans and bots completes |
| 3 | Single-player viewport per device | Each device shows its own player; checksums still match |
| 4 | Disconnect handling, ⋯ menu policy, privacy exception, docs | Clean end on drop; reviewed network boundary |

Stop at phase 0 if checksums cannot be made to match; record which system
diverges.

## When to start

When the original build's stability work is done and the owner asks for
netplay. This plan does not change decision 0011's current result.
