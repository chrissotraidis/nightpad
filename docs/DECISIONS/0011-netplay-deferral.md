# Decision 0011: defer online netplay

Date: 2026-10-28

## Result

NightPad ships the original **local** multiplayer: split screen, four human
ports and six bots. Online play is deferred. No online feature is claimed and
R23 stays not applicable.

## Evidence

- A search of the reconstructed engine for `WSAStartup`, `XNet`, `XOnline`,
  `DirectPlay`, `sockaddr` and `netplay` finds no networking code; the only
  matches are unrelated identifiers such as `wSamplesPerBlock`.
- The front-end text bank has Multiplayer, Multiplayer Options, bots and rules,
  but no System Link, LAN or online entry.
- `docs/MULTIPLAYER-INVENTORY.md` lists only local settings: players, bots,
  modes, maps, weapon sets, respawn, mods and split layout.
- The three-dot shell, input mixer and engine bridge have no transport or
  session concept, so there is no seam to attach netplay to today.

## Approaches considered

1. **Emulate Xbox System Link / XNet.** Implement the Xbox network APIs, LAN
   discovery and the original session protocol, then keep the game's own
   simulation in sync. This needs an unimplemented platform layer and an
   unknown wire protocol; feasibility is not established.
2. **Host-authoritative netplay in the host layer.** Stream inputs to a host,
   run the authoritative simulation there and replicate state or run rollback.
   This is new architecture, needs determinism evidence the project does not
   have, and would have to be adopted by every gameplay system.

Both are larger than the private-candidate scope and neither has source
support. A positive prototype would still leave R23's two-device consistency,
impairment and disconnect work open.

## When to revisit

- Upstream adds a networking layer or system-link support.
- Chris explicitly asks for netplay as a new feature.
- A host-authoritative determinism study shows the simulation is reproducible
  enough to make rollback practical.

Until then, multiplayer work stays on local modes, bots and ports.
