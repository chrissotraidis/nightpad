#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nf="$repo/vendor/nightfire"
build="$nf/build/macos-arm64"
out="$repo/build/tests/action-lifecycle"
mkdir -p "$out" "$out/run"
sdk=$(xcrun --sdk macosx --show-sdk-path)
common="-arch arm64 -isysroot $sdk -mmacosx-version-min=15.0 -std=gnu++20 -ffp-contract=off -fms-extensions -fno-exceptions -Wno-ignored-attributes -DNIGHTFIRE_STANDALONE=1 -DNIGHTFIRE_SDL=1 -DNIGHTFIRE_WINDOW_BASE=0x100000000 -I $nf/src"

clang++ $common -c "$repo/apple/shared/NightPadActionEngineEntry.cpp" -o "$out/entry.o"
clang++ $common -c "$repo/apple/shared/NightPadActionRuntime.cpp" -o "$out/runtime.o"
find "$build/CMakeFiles/action_standalone.dir" -name '*.o' \
    ! -name 'StandaloneMain.o' ! -name 'StandaloneMain.cpp.o' | sort > "$out/objects.txt"
ld -r -arch arm64 -o "$out/combined-raw.o" -filelist "$out/objects.txt" "$out/entry.o" "$out/runtime.o"
cat > "$out/exports.txt" <<'EOF'
_NightPadActionEngineThread
_NightPadActionEngineSetLaunchRequestCallback
_NightPadActionEngineRequestStop
_NightPadActionEngineStart
_NightPadActionEngineRunWindow
_NightPadActionEngineJoin
_NightPadActionEngineCloseWindow
EOF
nmedit -s "$out/exports.txt" -o "$out/combined.o" "$out/combined-raw.o"
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -I "$repo/apple/shared" -c "$repo/tests/native/test_action_lifecycle.cpp" -o "$out/main.o"
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -Wl,-no_fixup_chains \
    -Wl,-rpath,@executable_path -o "$out/test_action_lifecycle" "$out/main.o" "$out/combined.o" \
    "$build/_deps/sdl3-build/libSDL3.0.dylib" \
    "$build/_deps/spirv_cross-build/libspirv-cross-msl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-glsl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-core.a"

printf '[Settings]\nDiscPath=%s\nRenderWidth=640\nRenderHeight=480\nRegion=NTSC\nFPS=60\n' \
    "$repo/build/data/experiment-pal-video-25" > "$out/run/settings.ini"
cd "$out/run"
SDL_VIDEO_DRIVER=offscreen SDL_AUDIODRIVER=dummy \
    DYLD_LIBRARY_PATH="$build:$repo/build/deps/ffmpeg-macos-arm64/lib" \
    ../test_action_lifecycle

