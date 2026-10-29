#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d /tmp/nightpad-perf.XXXXXX)
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

cat > "$tmp/action.log" <<'EOF'
[perf] 50.0 fps (asked for 60), 10.0 ms working + 2.0 ms waiting per frame
[perf] 60.0 fps (asked for 60), 12.0 ms working + 0.0 ms waiting per frame
[perf] 40.0 fps (asked for 60), 20.0 ms working + 5.0 ms waiting per frame
EOF

python3 "$repo/scripts/summarize_perf.py" "$tmp/action.log" --label action > "$tmp/out.json"
python3 "$repo/scripts/summarize_perf.py" "$tmp/action.log" --skip 1 --label steady > "$tmp/skip.json"
TMPDIR_FOR_TEST="$tmp" python3 - <<'PY'
import json, os
base = os.environ["TMPDIR_FOR_TEST"]
d = json.load(open(os.path.join(base, "out.json")))
run = d["runs"][0]
assert run["samples"] == 3, run
assert run["fps"]["mean"] == 50.0 and run["fps"]["min"] == 40.0 and run["fps"]["max"] == 60.0, run
assert run["working_ms"]["mean"] == 14.0 and run["working_ms"]["max"] == 20.0, run
assert run["waiting_ms"]["max"] == 5.0 and run["route"] == "action", run
assert run["asked_fps"] == [60], run
skip = json.load(open(os.path.join(base, "skip.json")))["runs"][0]
assert skip["samples"] == 2, skip
assert skip["fps"]["mean"] == 50.0 and skip["fps"]["min"] == 40.0, skip
PY

echo "no samples here" > "$tmp/empty.log"
if python3 "$repo/scripts/summarize_perf.py" "$tmp/empty.log" > /dev/null 2>&1; then
    echo "perf summary: a log with no samples must fail" >&2
    exit 1
fi

echo "perf summary: PASS"
