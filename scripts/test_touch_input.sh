#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out="$repo/build/tests/touch-input"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)

clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -I "$repo/apple/shared" "$repo/apple/shared/NightPadTouchLayout.cpp" \
    "$repo/apple/shared/NightPadInput.cpp" "$repo/apple/shared/NightPadTouchInput.cpp" \
    "$repo/tests/native/test_touch_input.cpp" -o "$out/test_touch_input"
"$out/test_touch_input"
