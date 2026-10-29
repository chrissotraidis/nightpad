#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nf="$repo/vendor/nightfire"
native="$nf/build/macos-arm64"
out="$repo/build/tests/fmv-pause"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)
clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -DNIGHTFIRE_SDL=1 -I "$nf/src" -I "$nf/third_party/ffmpeg-prebuilt/include" \
    -I "$native/_deps/sdl3-src/include" -Wl,-rpath,"$native/_deps/sdl3-build" \
    "$repo/tests/native/test_fmv_audio.cpp" "$nf/src/common/fmv/FmvAudioSdl.cpp" \
    "$native/_deps/sdl3-build/libSDL3.0.dylib" -o "$out/test_fmv_audio"
SDL_AUDIODRIVER=dummy "$out/test_fmv_audio"
