#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out="$repo/build/tests/data-import"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)

clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -I "$repo/apple/shared" \
    "$repo/apple/shared/NightPadPaths.cpp" \
    "$repo/apple/shared/NightPadGameDataImport.cpp" \
    "$repo/tests/native/test_data_import.cpp" \
    -o "$out/test_data_import"
"$out/test_data_import"
