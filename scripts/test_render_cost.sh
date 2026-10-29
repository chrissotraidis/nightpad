#!/bin/sh
set -eu

# Measures driving-gameplay frame rate at 1x, 2x and 3x render targets on this
# Mac. Not a device claim: it shows how the scene cost grows with the target.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nf="$repo/vendor/nightfire"
build="$nf/build/macos-arm64"
driving="$repo/build/tests/driving-lifecycle"
out="$repo/build/tests/render-cost"
sdk=$(xcrun --sdk macosx --show-sdk-path)
mkdir -p "$out" "$out/run"

"$repo/scripts/test_driving_lifecycle.sh" > "$out/build.log" 2>&1

clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -I "$repo/apple/shared" \
    -c "$repo/tests/native/test_render_cost.cpp" -o "$out/main.o"
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -Wl,-no_fixup_chains \
    -Wl,-rpath,@executable_path -o "$out/test_render_cost" "$out/main.o" \
    "$driving/shared-runtime.o" "$driving/combined.o" \
    "$build/_deps/sdl3-build/libSDL3.0.dylib" \
    "$build/_deps/spirv_cross-build/libspirv-cross-msl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-glsl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-core.a"

cd "$out/run"
for scale in 1 2 3; do
    width=$((640 * scale))
    height=$((480 * scale))
    printf '[Settings]\nDiscPath=%s\nRenderWidth=%d\nRenderHeight=%d\nRegion=NTSC\nFPS=60\n' \
        "$repo/build/data/experiment-pal-video-25" "$width" "$height" > settings.ini
    SDL_VIDEO_DRIVER=offscreen SDL_AUDIODRIVER=dummy NIGHTPAD_PLAY_SECONDS=20 \
        DYLD_LIBRARY_PATH="$build:$repo/build/deps/ffmpeg-macos-arm64/lib" \
        ../test_render_cost > "cost-$scale.log" 2>&1 || {
            echo "render cost: $width x $height run failed; see $out/run/cost-$scale.log" >&2
            exit 1
        }
    fps=$(grep -o '\[perf\] [0-9.]* fps' "cost-$scale.log" | tail -1 | awk '{print $2}')
    if [ -z "$fps" ]; then
        echo "render cost: no frame-rate sample at $width x $height" >&2
        exit 1
    fi
    echo "$width x $height: $fps fps"
done
echo "render cost: measured (macOS host; not a device result)"
