#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out="$repo/build/tests/touch-policy"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)

clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -I "$repo/apple/shared" "$repo/apple/shared/NightPadTouchPolicy.cpp" \
    "$repo/tests/native/test_touch_policy.cpp" -o "$out/test_touch_policy"
"$out/test_touch_policy"
