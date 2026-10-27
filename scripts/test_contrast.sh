#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out="$repo/build/tests/contrast"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)

clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -I "$repo/apple/shared" "$repo/apple/shared/NightPadControlPalette.cpp" \
    "$repo/apple/shared/NightPadTouchLayout.cpp" \
    "$repo/tests/native/test_contrast.cpp" -o "$out/test_contrast"
"$out/test_contrast"
