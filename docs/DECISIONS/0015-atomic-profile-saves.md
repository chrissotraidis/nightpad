# Decision 0015: preserve profiles through interrupted writes

Date: 2026-10-28

The POSIX engine save path previously opened `saves/<codename>.dat` with
`fopen(..., "wb")`. That truncates the only profile before its replacement
is written and ignores an error from `fclose`. A killed process or failed
write can therefore destroy the player's previous progress.

Patch 0028 replaces that write on Apple/POSIX hosts with a transaction:

1. Write the original serialized bytes into a unique hidden sibling file.
   Handle short writes and `EINTR`, then flush and close it successfully.
2. If a profile already exists, copy it to another hidden sibling, flush and
   close the copy, and atomically install it as `<codename>.dat.bak`.
3. Flush the directory, rename the new profile over the live `.dat`, then
   flush the directory again. Any failure reports the existing engine save
   failure state. A failure after promotion can leave the complete new save.

The live profile is never truncated. The backup holds the preceding profile;
neither backups nor hidden transaction files match the game's `*.dat` list.
Hidden stages also stay out of the shell's Share Saves export. A killed
writer may leave one hidden stage; subsequent writes use unique names and
do not read or promote it. Explicit codename deletion also removes its backup.
Windows retains its existing writer with a checked close result.

Share Saves includes the `.bak` file. To recover the previous profile, export
it, make a copy named `<codename>.dat`, stop the game, and restore that copy
through Import Saves. Backups are not loaded automatically or treated as
additional codenames. The original save format and progression rules stay
unchanged: campaign progress is written when continuing past mission results,
not at every objective or level-part transition.

`scripts/test_engine_save.sh` exercises the production writer under short
writes, `EINTR`, `ENOSPC`, zero-byte writes, read failures, file and directory
flush failures, close failure, and failed backup/commit renames. It kills
child writers with `SIGKILL` immediately before and after the live rename,
then checks old/new bytes, the previous copy, unrelated profiles, and
enumeration/export exclusions. It also calls the actual `psiSaveData`,
`psiLoadData`, poll and delete entry points with synthetic profile bytes, including reloading
a restored previous copy.

These host tests cover process interruption and failed system calls. They
do not prove physical-device power-loss durability, a completed campaign
mission, or signed update behavior. Those acceptance rows remain open.

The simulator's original Save Codename flow changed one controller-scheme byte
in a real 166-byte profile and reloaded the new scheme after app relaunch.
The previous copy matched exactly. An original Secret Unlock also completed
save/update/relaunch/reversal through the same writer on the final build,
without changing the existing profiles. Private evidence is indexed under
`evidence/save-durability/`.
