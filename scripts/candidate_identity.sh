#!/bin/sh
set -eu

# Prints the identity fields the candidate manifest needs. Run with
# --require-clean to fail on an uncommitted tree (freeze time).
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo"
require_clean=0
if [ $# -gt 0 ] && [ "$1" = "--require-clean" ]; then
    require_clean=1
fi

head=$(git rev-parse HEAD)
branch=$(git rev-parse --abbrev-ref HEAD)
dirty=$(git status --porcelain | wc -l | tr -d ' ')
pin=$(python3 -c "import json;print(json.load(open('config/dependencies.lock.json'))['source_graph']['nightfire']['revision'])")
vendor_head=$(git -C vendor/nightfire rev-parse HEAD)
lock_hash=$(shasum -a 256 config/dependencies.lock.json | awk '{print $1}')
patch_count=$(ls patches/00*.patch | wc -l | tr -d ' ')
patch_hash=$(cat patches/00*.patch | shasum -a 256 | awk '{print $1}')

python3 - <<'PY' || exit 1
import json, os, subprocess, sys
graph = json.load(open("config/dependencies.lock.json"))["source_graph"]
bad = []
for name, entry in graph.items():
    path = entry.get("path")
    revision = entry.get("revision")
    if not path or not revision:
        continue
    if not os.path.isdir(path):
        bad.append(f"{name}: checkout missing at {path}")
        continue
    result = subprocess.run(["git", "-C", path, "rev-parse", "HEAD"], capture_output=True, text=True)
    if result.returncode != 0:
        bad.append(f"{name}: not a readable checkout at {path}")
        continue
    head = result.stdout.strip()
    if head != revision:
        bad.append(f"{name}: HEAD {head} does not match pin {revision}")
        continue
    print(f"donor_ok={name}@{revision}")
if bad:
    for line in bad:
        print("candidate: " + line, file=sys.stderr)
    sys.exit(1)
PY

echo "commit=$head"
echo "branch=$branch"
echo "tree=$([ "$dirty" -eq 0 ] && echo clean || echo dirty)"
echo "engine_pin=$pin"
echo "engine_head=$vendor_head"
echo "dependency_lock_sha256=$lock_hash"
echo "patches=$patch_count"
echo "patch_series_sha256=$patch_hash"

if [ -f build/data/current.json ]; then
    python3 - <<'PY'
import json
from pathlib import Path
d = json.load(open("build/data/current.json"))
print("data_identity=" + d.get("identity", ""))
manifest = Path(d.get("manifest", ""))
if manifest.is_file():
    try:
        m = json.load(open(manifest))
        source = m.get("source", {}) if isinstance(m, dict) else {}
        if isinstance(source, dict) and source.get("sha256"):
            print("content_sha256=" + str(source["sha256"]))
            raise SystemExit(0)
        for key in ("source_sha256", "sourceSha256", "sha256"):
            if key in m:
                print("content_sha256=" + str(m[key]))
                break
    except Exception:
        pass
PY
fi

ipa=build/package/NightPadShell-unsigned.ipa
if [ -f "$ipa" ]; then
    echo "ipa_sha256=$(shasum -a 256 "$ipa" | awk '{print $1}')"
fi

if [ "$require_clean" -eq 1 ] && [ "$dirty" -ne 0 ]; then
    echo "candidate: the tree is dirty; commit before freezing" >&2
    exit 1
fi
