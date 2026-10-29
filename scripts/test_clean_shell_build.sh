#!/bin/sh
set -eu

# Proves both shell lanes configure and build with no stale CMake/Xcode output.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
"$repo/scripts/build_ios_shell.sh" simulator debug --clean >/dev/null
"$repo/scripts/build_ios_shell.sh" device debug --clean >/dev/null
"$repo/scripts/check_ios_shell_link.sh"
echo "clean shell build: PASS (simulator and device from empty build trees)"
