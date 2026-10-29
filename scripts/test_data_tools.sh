#!/bin/sh
set -eu

# Host tests for the Python data tools: disc listing validation, the BIGF and
# RefPack readers, and the driving track inspector.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
python3 "$repo/tests/test_data_tools.py"
echo "data tools: PASS"
