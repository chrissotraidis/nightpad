#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out="$repo/build/tests/presentation"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)
clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -I "$repo/vendor/nightfire/src" \
    "$repo/tests/native/test_presentation.cpp" -o "$out/test_presentation"
"$out/test_presentation"
