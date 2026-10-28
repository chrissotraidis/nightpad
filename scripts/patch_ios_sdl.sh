#!/bin/sh
set -eu

# SDL 3.4.18 rejects the iOS Simulator's Metal device because that device
# exposes the host GPU rather than an Apple GPU family. Keep the pinned SDL
# source otherwise unchanged, and make the compatibility edit idempotent.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
lane=${1:-simulator}
if [ "$lane" != simulator ]; then
    exit 0
fi

source="$repo/build/nightfire-ios-simulator/_deps/sdl3-src"
patch_file="$repo/patches/sdl3-ios-simulator-metal.patch"
if [ ! -d "$source" ]; then
    echo "SDL3 source is not configured for the simulator" >&2
    exit 1
fi
if grep -q "The Simulator's Metal device exposes" "$source/src/gpu/metal/SDL_gpu_metal.m"; then
    exit 0
fi
git -C "$source" apply "$patch_file"
echo "Applied iOS Simulator Metal compatibility to pinned SDL3"
