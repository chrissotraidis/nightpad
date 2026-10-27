#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out="$repo/build/tests/input"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)

clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -I "$repo/apple/shared" "$repo/apple/shared/NightPadInput.cpp" \
    "$repo/tests/native/test_input.cpp" -o "$out/test_input"
"$out/test_input"
