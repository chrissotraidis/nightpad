#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nf="$repo/vendor/nightfire"
build="$nf/build/macos-arm64"
action="$repo/build/tests/action-lifecycle"
out="$repo/build/tests/action-boot"
sdk=$(xcrun --sdk macosx --show-sdk-path)
mkdir -p "$out"
"$repo/scripts/test_action_lifecycle.sh" > "$out/build.log" 2>&1
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -std=gnu++20 \
    -fms-extensions -Wno-ignored-attributes -DNIGHTFIRE_STANDALONE=1 \
    -I "$nf/src" -c "$repo/tests/native/test_action_boot.cpp" -o "$out/main.o"
# The raw object keeps the engine's private boot functions visible to this
# regression; the app continues to export only its existing bridge API.
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -Wl,-no_fixup_chains \
    -Wl,-rpath,@executable_path -o "$out/test_action_boot" "$out/main.o" \
    "$action/shared-runtime.o" "$action/combined-raw.o" \
    "$build/_deps/sdl3-build/libSDL3.0.dylib" \
    "$build/_deps/spirv_cross-build/libspirv-cross-msl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-glsl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-core.a"
DYLD_LIBRARY_PATH="$build:$repo/build/deps/ffmpeg-macos-arm64/lib" "$out/test_action_boot"
