#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nf="$repo/vendor/nightfire"
build="$nf/build/macos-arm64"
action="$repo/build/tests/action-lifecycle"
driving="$repo/build/tests/driving-lifecycle"
out="$repo/build/tests/engine-transition"
sdk=$(xcrun --sdk macosx --show-sdk-path)
mkdir -p "$out" "$out/run"

# Rebuild each isolated engine and its one shared host allocator before combining them.
"$repo/scripts/test_action_lifecycle.sh" > "$out/action-build.log" 2>&1
"$repo/scripts/test_driving_lifecycle.sh" > "$out/driving-build.log" 2>&1

clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -I "$repo/apple/shared" \
    -c "$repo/tests/native/test_engine_transition.cpp" -o "$out/main.o"
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -Wl,-no_fixup_chains \
    -Wl,-rpath,@executable_path -o "$out/test_engine_transition" "$out/main.o" \
    "$action/shared-runtime.o" "$action/combined.o" "$driving/combined.o" \
    "$build/_deps/sdl3-build/libSDL3.0.dylib" \
    "$build/_deps/spirv_cross-build/libspirv-cross-msl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-glsl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-core.a"

printf '[Settings]\nDiscPath=%s\nRenderWidth=640\nRenderHeight=480\nRegion=NTSC\nFPS=60\n' \
    "$repo/build/data/experiment-pal-video-25" > "$out/run/settings.ini"
cd "$out/run"
python3 -c 'import os; os.path.exists("psiLaunch.bin") and os.unlink("psiLaunch.bin")'
SDL_VIDEO_DRIVER=offscreen SDL_AUDIODRIVER=dummy \
    DYLD_LIBRARY_PATH="$build:$repo/build/deps/ffmpeg-macos-arm64/lib" \
    ../test_engine_transition -mission 1

