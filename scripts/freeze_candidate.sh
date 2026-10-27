#!/bin/sh
set -eu

# One command for the private-candidate freeze: clean tree, gates, identity and
# package, with the evidence concatenated into build/package/candidate.txt.
# --full adds the slow engine suite. Device acceptance is never claimed here.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
full=0
if [ $# -gt 0 ] && [ "$1" = "--full" ]; then
    full=1
elif [ $# -gt 0 ]; then
    echo "usage: $0 [--full]" >&2
    exit 2
fi

if [ -n "$(git -C "$repo" status --porcelain)" ]; then
    echo "freeze: the tree is dirty; commit or stash before freezing" >&2
    git -C "$repo" status --short >&2
    exit 1
fi

out="$repo/build/package"
mkdir -p "$out"
log="$out/candidate.txt"
step() {
    label=$1
    shift
    printf '\n== %s\n' "$label" >> "$log"
    if ! "$@" >> "$log" 2>&1; then
        echo "freeze: $label failed; see $log" >&2
        tail -20 "$log" >&2
        exit 1
    fi
}

{
    echo "NightPad candidate evidence"
    echo "generated_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "commit=$(git -C "$repo" rev-parse HEAD)"
    echo "tree=clean"
} > "$log"

step "quick gates" "$repo/scripts/verify_quick.sh"
if [ "$full" -eq 1 ]; then
    step "engine suite" "$repo/scripts/verify_engine.sh"
fi
step "device package" "$repo/scripts/package_device_app.sh"
step "identity" "$repo/scripts/candidate_identity.sh" --require-clean
printf '\ndevice acceptance: not claimed; run scripts/device_handoff.sh with an identity and device\n' >> "$log"
tail -25 "$log"
