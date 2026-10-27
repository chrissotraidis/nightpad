#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nf="$repo/vendor/nightfire"
build="$nf/build/macos-arm64"
out="$repo/build/tests/driving-lifecycle"
mkdir -p "$out" "$out/run"
sdk=$(xcrun --sdk macosx --show-sdk-path)
common="-arch arm64 -isysroot $sdk -mmacosx-version-min=15.0 -std=gnu++20 -ffp-contract=off -fms-extensions -fno-exceptions -Wno-ignored-attributes -DNIGHTFIRE_STANDALONE=1 -DNIGHTFIRE_SDL=1 -DNIGHTFIRE_WINDOW_BASE=0x100000000 -I $nf/src -I $nf/third_party/ffmpeg-prebuilt/include"

clang++ $common -c "$repo/apple/shared/NightPadDrivingEngineEntry.cpp" -o "$out/entry.o"
clang++ $common -c "$repo/apple/shared/NightPadDrivingRuntime.cpp" -o "$out/runtime.o"
find "$build/CMakeFiles/driving_standalone.dir" -name '*.o' ! -name 'GameWindow.cpp.o' ! -name 'HostPosix.cpp.o' > "$out/objects.txt"
printf '%s\n%s\n' \
    "$build/CMakeFiles/driving_standalone.dir/src/driving/platform/GameWindow.cpp.o" \
    "$build/CMakeFiles/driving_standalone.dir/src/driving/platform/HostPosix.cpp.o" > "$out/shared.txt"
ld -r -arch arm64 -o "$out/combined-raw.o" -filelist "$out/objects.txt" "$out/entry.o" "$out/runtime.o"
ld -r -arch arm64 -o "$out/shared-runtime.o" -filelist "$out/shared.txt"
cat > "$out/exports.txt" <<'EOF'
_NightPadDrivingEngineThread
_NightPadDrivingEngineSetLaunchRequestCallback
_NightPadDrivingEngineRequestStop
_NightPadDrivingEngineStart
_NightPadDrivingEngineRunWindow
_NightPadDrivingEnginePollWindow
_NightPadDrivingEngineSetPaused
_NightPadDrivingEngineSetInputSuspended
_NightPadDrivingEngineAudioPaused
_NightPadDrivingEngineSetHostPadsEnabled
_NightPadDrivingEngineSetHostPad
_NightPadDrivingEngineSetRumbleHandler
_NightPadDrivingEngineFrameCount
_NightPadDrivingEngineJoin
_NightPadDrivingEngineCloseWindow
EOF
nmedit -s "$out/exports.txt" -o "$out/combined.o" "$out/combined-raw.o"
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -DNIGHTPAD_DRIVING_LIFECYCLE \
    -I "$repo/apple/shared" -c "$repo/tests/native/test_action_lifecycle.cpp" -o "$out/main.o"
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -Wl,-no_fixup_chains \
    -Wl,-rpath,@executable_path -o "$out/test_driving_lifecycle" "$out/main.o" "$out/shared-runtime.o" "$out/combined.o" \
    "$build/_deps/sdl3-build/libSDL3.0.dylib" \
    "$build/_deps/spirv_cross-build/libspirv-cross-msl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-glsl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-core.a"
printf '[Settings]\nDiscPath=%s\nRenderWidth=640\nRenderHeight=480\nRegion=NTSC\nFPS=60\n' \
    "$repo/build/data/experiment-pal-video-25" > "$out/run/settings.ini"
cd "$out/run"
SDL_VIDEO_DRIVER=offscreen SDL_AUDIODRIVER=dummy \
    DYLD_LIBRARY_PATH="$build:$repo/build/deps/ffmpeg-macos-arm64/lib" \
    NIGHTPAD_LIFECYCLE_CYCLES=${NIGHTPAD_LIFECYCLE_CYCLES:-1} \
    ../test_driving_lifecycle -mission 1

