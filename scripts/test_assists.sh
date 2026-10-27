#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nf="$repo/vendor/nightfire"
build="$nf/build/macos-arm64"
action="$repo/build/tests/action-lifecycle"
out="$repo/build/tests/assists"
sdk=$(xcrun --sdk macosx --show-sdk-path)
mkdir -p "$out" "$out/run"

"$repo/scripts/test_action_lifecycle.sh" > "$out/build.log" 2>&1

clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -I "$repo/apple/shared" \
    -c "$repo/tests/native/test_assists.cpp" -o "$out/main.o"
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -Wl,-no_fixup_chains \
    -Wl,-rpath,@executable_path -o "$out/test_assists" "$out/main.o" \
    "$action/shared-runtime.o" "$action/combined.o" \
    "$build/_deps/sdl3-build/libSDL3.0.dylib" \
    "$build/_deps/spirv_cross-build/libspirv-cross-msl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-glsl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-core.a"

printf '[Settings]\nDiscPath=%s\nRenderWidth=640\nRenderHeight=480\nRegion=NTSC\nFPS=60\n' \
    "$repo/build/data/experiment-pal-video-25" > "$out/run/settings.ini"
cd "$out/run"

SDL_VIDEO_DRIVER=offscreen SDL_AUDIODRIVER=dummy \
    DYLD_LIBRARY_PATH="$build:$repo/build/deps/ffmpeg-macos-arm64/lib" \
    ../test_assists
