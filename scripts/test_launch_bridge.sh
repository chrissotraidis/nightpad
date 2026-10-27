#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$repo/build/tests"
sdk=$(xcrun --sdk macosx --show-sdk-path)
clang++ -isysroot "$sdk" -arch arm64 -std=c++17 -ffp-contract=off -fms-extensions \
    -Wno-ignored-attributes -I "$repo/vendor/nightfire/src" \
    "$repo/tests/native/test_launch_bridge.cpp" \
    "$repo/vendor/nightfire/src/common/launchInfo.cpp" \
    -o "$repo/build/tests/test_launch_bridge" -pthread
"$repo/build/tests/test_launch_bridge"

