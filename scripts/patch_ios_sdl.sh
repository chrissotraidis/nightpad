#!/bin/sh
set -eu

# Two edits to the pinned SDL 3.4.18 source configured for a lane, both
# idempotent:
# - every lane: the UIKit scene-geometry correction shared with the other SDL3
#   Pad ports (patches/sdl3-uikit-scene-geometry.patch): SDL runs NightPad only
#   in the application scene it started in, leaves an external display to the
#   system, and takes orientation from that scene;
# - simulator: SDL 3.4.18 rejects the iOS Simulator's Metal device because that
#   device exposes the host GPU rather than an Apple GPU family.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
lane=${1:-simulator}
case "$lane" in
    simulator|device) ;;
    *) echo "usage: $0 [simulator|device]" >&2; exit 2 ;;
esac

source="$repo/build/nightfire-ios-$lane/_deps/sdl3-src"
if [ ! -d "$source" ]; then
    echo "SDL3 source is not configured for the $lane lane" >&2
    exit 1
fi

if ! grep -q "UIKit_OwningSceneDidDisconnect" "$source/src/video/uikit/SDL_uikitvideo.m"; then
    git -C "$source" apply "$repo/patches/sdl3-uikit-scene-geometry.patch"
    echo "Applied the UIKit scene-geometry correction to pinned SDL3 ($lane)"
fi

if [ "$lane" = simulator ] &&
   ! grep -q "The Simulator's Metal device exposes" "$source/src/gpu/metal/SDL_gpu_metal.m"; then
    git -C "$source" apply "$repo/patches/sdl3-ios-simulator-metal.patch"
    echo "Applied iOS Simulator Metal compatibility to pinned SDL3"
fi
