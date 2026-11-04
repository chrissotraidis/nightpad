# Private candidate manifest (draft)

> **Historical.** This draft predates the public 0.2.0 preview (2026-11-05) and
> its device statements are out of date: the app is signed and played on an
> iPad Pro. For the current state see [STATUS](STATUS.md), the README's
> testing status and [KNOWN-ISSUES](KNOWN-ISSUES.md).

Status: **draft, not accepted**. This is the handoff document R30 asks for,
filled with what is verified today. Device gates are open, so it must be
refreshed at freeze time.

## Identity

Run `scripts/candidate_identity.sh --require-clean` at freeze. It prints the
commit, tree state, engine pin, dependency-lock hash, patch-series hash, data
identity, content hash and package hash, and refuses a dirty tree. Do not trust
a value copied from an older draft.

It also verifies every pinned checkout in `source_graph` — engine, GalaxyPad,
SunPad, extract-xiso and the FFmpeg submodule — and fails on drift before
printing any identity.

Draft snapshot from 2026-10-28 (illustrative; regenerate). Taken at commit
`3e17474` on a clean tree:

```
engine_pin=8779cf79ff623b83b53b9acf9c0b0cd6639b75ab
patches=17
patch_series_sha256=5331fea387832e7e7f6072a41e5926a864a4eee6e783d9aec90e6cdf43f2356c
dependency_lock_sha256=f2ae8ce569ba6fe8676fdfcdc4bd4a4c9a490aa483d1d661afed2dd63742b08e
data_identity=data-8a0dc0e713f44e48b000
content_sha256=8a0dc0e713f44e48b00054ca021fb027571e6f7877b8225cc5ae275af2435ebe
ipa_sha256=74733f53b143661d386984273ddd25c0d127783826fc6aab3e69ee40d4c52c58
```

`scripts/package_device_app.sh` rebuilt the unsigned 3.6 MB IPA on that tree;
it rebuilds the zip on every run, so the hash changes with the archive's
timestamps even when the app is identical. `build/candidate.txt` is the record.

The fields a freeze must record:

- Repository commit: `git rev-parse HEAD`
- Engine pin: `8779cf79ff623b83b53b9acf9c0b0cd6639b75ab`
- Patch series: `patches/0001`..`0017`, verified by
  `scripts/verify_patches.sh` (57 files reproduced)
- Dependency lock: `config/dependencies.lock.json`
- Data identity: the imported tree's `manifest.json` (currently
  `data-a3c98ab965ac41e559ac` in the simulator)
- Unsigned package: `build/package/NightPadShell-unsigned.ipa` with its
  printed SHA-256

## Support matrix

| Target | Status |
| --- | --- |
| iPhone, iOS 16+, landscape | shell builds and links; device acceptance blocked |
| iPad, iOS 16+, landscape | same, plus tablet touch defaults |
| MFi / Xbox controller | GameController authority implemented; physical runs blocked |
| Simulator | UI, import, layout editor, overlay, accessibility and diagnostics verified |
| macOS engine harness | lifecycles, pause/audio, transitions, handoff and round trip verified |

## Verified evidence

- `scripts/verify_quick.sh`: host logic, both shell builds, device link
  contract, patch provenance and privacy.
- `scripts/verify_engine.sh`: action and driving lifecycles, pause with audio,
  assists, early stop, transitions, handoff and round trip.
- `docs/TEST-MATRIX.md`: requirement-by-requirement verdicts.
- `docs/DEVICE-HANDOFF.md`: the physical session checklist.
- `docs/PERFORMANCE-BUDGET.md`: the routes and numeric budgets to measure
  during the device pass.
 - `docs/KNOWN-ISSUES.md`: the open issues and the things that look like
   issues but are not.
- Simulator captures under ignored `evidence/ios-shell/`.

## Known issues and gaps

- No signing identity and no connected device: every physical acceptance item
  is blocked.
- The supplied image has no PAL `25_fps` media; NightPad writes
  `Region=NTSC` and one recording still expects a 25 fps movie.
- All-weapons equip is deferred; direct level boot crashes the standalone
  harness, so there is no scripted live player.
- The Files and save pickers present but cannot be driven from the harness;
  selection is manual.
- Stop during engine boot is held until the first frame because the original
  cleanup crash was never explained.
- Host render cost is capped around 50 fps at every scale; device performance
  is unmeasured.
- Online netplay is deferred (decision 0011); R23 is not applicable.
- Multiplayer maps, modes and unlock rules are inventoried but no match has run.

## Next step

Provide a signing identity and a trusted device, run
`scripts/device_handoff.sh --install --team=<TEAMID>`, and work the checklist.
After the device pass, refresh this manifest with the final commit, package hash,
device results and a candidate identity, then mark R30's evidence.
