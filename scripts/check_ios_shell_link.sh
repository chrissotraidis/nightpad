#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app="$repo/build/ios-shell-device/Debug-iphoneos/NightPadShell.app/NightPadShell"
if [ ! -f "$app" ]; then
    echo "Build the device shell first: scripts/build_ios_shell.sh device" >&2
    exit 1
fi

file "$app" | grep -q arm64
if otool -L "$app" | grep -Eq 'SDL3|libav|spirv'; then
    echo "NightPadShell still depends on a loose engine dylib" >&2
    exit 1
fi

symbols=$(nm -gU "$app")
for symbol in _NightPadActionEngineStart _NightPadActionEngineRequestStop \
              _NightPadActionEngineJoin _NightPadActionEngineCloseWindow \
              _NightPadDrivingEngineStart; do
    printf '%s\n' "$symbols" | grep -q " T $symbol$" || {
        echo "NightPadShell is missing $symbol" >&2
        exit 1
    }
done

echo "NightPadShell: arm64 app with action and driving engine symbols; no loose SDL/FFmpeg/SPIRV dylibs"
