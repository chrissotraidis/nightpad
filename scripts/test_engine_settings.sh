#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out="$repo/build/tests/engine-settings"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)

clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -fms-extensions -Wno-ignored-attributes -DNIGHTFIRE_STANDALONE=1 -Wl,-dead_strip \
    -include "$repo/vendor/nightfire/src/common/linux/msvcNames.h" \
    -I "$repo/apple/shared" -I "$repo/vendor/nightfire/src" \
    "$repo/apple/shared/NightPadEngineSettings.cpp" \
    "$repo/vendor/nightfire/src/action/engine/XboxSettings.cpp" \
    "$repo/vendor/nightfire/src/driving/platform/KernelImports.cpp" \
    "$repo/vendor/nightfire/src/driving/platform/XboxXapi.cpp" \
    "$repo/vendor/nightfire/src/driving/platform/HostPosix.cpp" \
    "$repo/tests/native/test_engine_settings.cpp" -o "$out/test_engine_settings"
"$out/test_engine_settings"
"$out/test_engine_settings" narrow
"$out/test_engine_settings" wide
