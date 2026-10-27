#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
NIGHTPAD_PAUSE_TEST=1 NIGHTPAD_STOP_AFTER_S=20 NIGHTPAD_LIFECYCLE_CYCLES=1 \
    "$repo/scripts/test_action_lifecycle.sh"
