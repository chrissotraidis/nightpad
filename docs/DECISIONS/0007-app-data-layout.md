# Decision 0007: app data layout and import activation

Date: 2026-10-27

## Decision

NightPad owns six separate data classes in the app container:

| Class | Location |
| --- | --- |
| Validated game data | `Library/Application Support/NightPad/GameData/<identity>/` |
| Profiles and saves | `Library/Application Support/NightPad/Saves/` |
| Launch state | `Library/Application Support/NightPad/LaunchState/` |
| Regenerable caches | `Library/Caches/NightPad/` |
| Diagnostics | `Library/Logs/NightPad/` |
| User exports | `Documents/` |

The engine receives the active game-data path explicitly; it does not derive a
disc path from the executable or the working directory. Replacing game data
does not touch the saves tree.

A prepared tree is copied into a private sibling `GameData.import-*` directory.
The importer checks free space, validates the manifest SHA-256 identity and the
required `default.xbe`, `Driving.xbe`, `eurocom/` and `driving/` entries, rejects
links and unsafe relative paths, and reports byte progress. Cancellation removes
only that transaction's stage. Activation requires the engine to be stopped and
uses Darwin's atomic `RENAME_SWAP` when an identity is being replaced or
`RENAME_EXCL` for a new identity. A different identity updates the launch pointer
and retains the previous tree for explicit cleanup; a stale pointer can recover
by scanning valid identity directories. Saves remain untouched throughout.

## Evidence

`scripts/test_data_import.sh` covers the layout, missing required data, symlink
rejection, cancellation, activation refusal while running, successful import,
replacement with previous-data retention, cleanup, and stale-pointer recovery.
The core compiles into the iPhoneOS probe target.

## Remaining

The import picker/progress UI, native shell, three-dot menu, pause/input gates and
engine-session wiring are not implemented yet.
