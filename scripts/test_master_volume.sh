#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nf="$repo/vendor/nightfire"
native="$nf/build/macos-arm64"
out="$repo/build/tests/master-volume"
mkdir -p "$out"
sdk=$(xcrun --sdk macosx --show-sdk-path)
clang++ -std=c++20 -arch arm64 -isysroot "$sdk" -mmacosx-version-min=15.0 \
    -fms-extensions -Wno-ignored-attributes -DNIGHTFIRE_STANDALONE=1 -DNIGHTFIRE_SDL=1 \
    -DNIGHTFIRE_WINDOW_BASE=0x100000000 -I "$nf/src" -I "$native/_deps/sdl3-src/include" \
    -I "$nf/third_party/ffmpeg-prebuilt/include" \
    -include "$nf/src/common/linux/msvcNames.h" -Wl,-rpath,"$native/_deps/sdl3-build" \
    -Wl,-no_fixup_chains -Wl,-dead_strip \
    "$repo/tests/native/test_master_volume.cpp" "$nf/src/common/sound/voiceMixer.cpp" \
    "$nf/src/common/sound/xadpcm.cpp" "$nf/src/common/fmv/FmvAudioSdl.cpp" \
    "$nf/src/driving/platform/HostPosix.cpp" "$nf/src/driving/platform/GameWindow.cpp" \
    "$native/_deps/sdl3-build/libSDL3.0.dylib" -o "$out/test_master_volume"
SDL_AUDIODRIVER=dummy "$out/test_master_volume"
