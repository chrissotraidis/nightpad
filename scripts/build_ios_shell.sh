#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
lane=simulator
if [ $# -gt 0 ]; then
    lane=$1
fi
config_name=debug
if [ $# -gt 1 ]; then
    config_name=$2
fi
case "$config_name" in
    debug) configuration=Debug ;;
    release) configuration=Release ;;
    *) echo "usage: $0 [simulator|device] [debug|release]" >&2; exit 2 ;;
esac
clean=0
if [ $# -gt 2 ] && [ "$3" = "--clean" ]; then
    clean=1
fi
case "$lane" in
    simulator) sdk=iphonesimulator ;;
    device) sdk=iphoneos ;;
    *) echo "usage: $0 [simulator|device] [debug|release] [--clean]" >&2; exit 2 ;;
esac
build="$repo/build/ios-shell-$lane"
if [ "$clean" -eq 1 ]; then
    python3 - "$build" <<'PY'
import shutil, sys
shutil.rmtree(sys.argv[1], ignore_errors=True)
PY
fi

engine_args=""
case "$lane" in
    device) combined="$repo/build/ios-combined" ;;
    simulator) combined="$repo/build/ios-combined-simulator" ;;
esac
"$repo/scripts/build_combined_engine_link.sh" "$lane" >/dev/null
engine_archive="$combined/libnightpad-engines.a"
sdl="$repo/build/nightfire-ios-$lane/_deps/sdl3-build/Release-$sdk/libSDL3.a"
sdl_include="$repo/build/nightfire-ios-$lane/_deps/sdl3-src/include"
ffmpeg="$repo/build/deps/ffmpeg-ios-$lane"
spirv="$repo/build/nightfire-ios-$lane/_deps/spirv_cross-build/Release-$sdk"
if [ ! -f "$engine_archive" ] || [ ! -f "$sdl" ] || [ ! -f "$sdl_include/SDL3/SDL_main.h" ] || [ ! -d "$ffmpeg" ] || [ ! -d "$spirv" ]; then
    echo "Missing combined engine inputs for $lane; build the engines first." >&2
    exit 1
fi
engine_args="-DNIGHTPAD_ENGINE_ARCHIVE=$engine_archive -DNIGHTPAD_SDL_LIB=$sdl -DNIGHTPAD_SDL_INCLUDE_DIR=$sdl_include -DNIGHTPAD_FFMPEG_ROOT=$ffmpeg -DNIGHTPAD_SPIRV_ROOT=$spirv"

SDKROOT=$(xcrun --sdk "$sdk" --show-sdk-path) cmake -S "$repo/apple/ios" -B "$build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 $engine_args >/dev/null
xcodebuild -project "$build/NightPadPlatformProbe.xcodeproj" -scheme NightPadShell \
    -configuration "$configuration" -sdk "$sdk" -arch arm64 CODE_SIGNING_ALLOWED=NO build
