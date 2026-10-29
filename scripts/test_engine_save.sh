#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out="$repo/build/tests/engine-save"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)
clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -fms-extensions -Wno-ignored-attributes -DNIGHTFIRE_STANDALONE=1 \
    -I "$repo/vendor/nightfire/src" -include "$repo/vendor/nightfire/src/common/linux/msvcNames.h" \
    "$repo/tests/native/test_engine_save.cpp" \
    "$repo/vendor/nightfire/src/action/engine/psiSave.cpp" \
    -Wl,-dead_strip -o "$out/test_engine_save"
"$out/test_engine_save"
