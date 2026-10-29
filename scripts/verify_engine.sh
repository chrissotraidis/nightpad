#!/bin/sh
set -eu

# Slow engine gates. These run the reconstructed engines headlessly and take
# several minutes; the handoff gate boots a full driving mission.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

"$repo/scripts/test_action_lifecycle.sh"
"$repo/scripts/test_action_boot.sh"
"$repo/scripts/test_secret_unlocks.sh"
"$repo/scripts/test_driving_lifecycle.sh"
"$repo/scripts/test_action_pause.sh"
"$repo/scripts/test_action_pause_clock.sh"
"$repo/scripts/test_assists.sh"
"$repo/scripts/test_driving_pause.sh"
"$repo/scripts/test_driving_movie_pause.sh"
"$repo/scripts/test_driving_early_stop.sh"
"$repo/scripts/test_engine_transition.sh"
"$repo/scripts/test_engine_handoff.sh"
"$repo/scripts/test_engine_roundtrip.sh"
echo "engine verification: PASS"
