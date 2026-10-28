#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nf="$repo/vendor/nightfire"
build="$nf/build/macos-arm64"
driving="$repo/build/tests/driving-lifecycle"
out="$repo/build/tests/driving-movie-pause"
sdk=$(xcrun --sdk macosx --show-sdk-path)
mkdir -p "$out" "$out/run"

"$repo/scripts/test_driving_lifecycle.sh" > "$out/build.log" 2>&1

clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -I "$repo/apple/shared" \
    -c "$repo/tests/native/test_driving_movie_pause.cpp" -o "$out/main.o"
clang++ -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 -Wl,-no_fixup_chains \
    -Wl,-rpath,@executable_path -o "$out/test_driving_movie_pause" "$out/main.o" \
    "$driving/shared-runtime.o" "$driving/combined.o" \
    "$build/_deps/sdl3-build/libSDL3.0.dylib" \
    "$build/_deps/spirv_cross-build/libspirv-cross-msl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-glsl.a" \
    "$build/_deps/spirv_cross-build/libspirv-cross-core.a"

printf '[Settings]\nDiscPath=%s\nRenderWidth=640\nRenderHeight=480\nRegion=NTSC\nFPS=60\n' \
    "$repo/build/data/experiment-pal-video-25" > "$out/run/settings.ini"
cd "$out/run"

# A test-owned launch page, using the engine's existing clean handover seed.
# Override only the video standard so this data set plays its real NTSC intro.
# This fixture is not campaign-progress evidence and never enters app saves.
python3 - "$nf/src/driving/platform/LaunchOptions.cpp" <<'PY'
import pathlib, re, struct, sys
source = pathlib.Path(sys.argv[1]).read_text()
block = source.split('DEFAULT_PAGE[] = {', 1)[1].split('};', 1)[0]
words = re.findall(r'\{(0x[0-9a-f]+),\s*(0x[0-9a-f]+)\}', block)
assert words and any(int(offset, 16) == 0xa1c for offset, _ in words)
page = bytearray(3072)
for offset, value in words:
    struct.pack_into('<I', page, int(offset, 16), int(value, 16))
struct.pack_into('<I', page, 0xa1c, 0)  # LaunchPage::videoMode: NTSC
pathlib.Path('psiLaunch.bin').write_bytes(page)
print('movie fixture: clean engine handover, videoMode=NTSC, mission selected by CLI')
PY

SDL_VIDEO_DRIVER=offscreen SDL_AUDIODRIVER=dummy \
    DYLD_LIBRARY_PATH="$build:$repo/build/deps/ffmpeg-macos-arm64/lib" \
    ../test_driving_movie_pause
