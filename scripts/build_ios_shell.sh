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
case "$lane" in
    simulator) sdk=iphonesimulator ;;
    device) sdk=iphoneos ;;
    *) echo "usage: $0 [simulator|device] [debug|release]" >&2; exit 2 ;;
esac
build="$repo/build/ios-shell-$lane"

engine_args=""
if [ "$lane" = device ]; then
    "$repo/scripts/build_combined_engine_link.sh" >/dev/null
    engine_archive="$repo/build/ios-combined/libnightpad-engines.a"
    sdl="$repo/build/nightfire-ios-device/_deps/sdl3-build/Release-iphoneos/libSDL3.a"
    ffmpeg="$repo/build/deps/ffmpeg-ios-device"
    spirv="$repo/build/nightfire-ios-device/_deps/spirv_cross-build/Release-iphoneos"
    if [ ! -f "$engine_archive" ] || [ ! -f "$sdl" ] || [ ! -d "$ffmpeg" ] || [ ! -d "$spirv" ]; then
        echo "Missing combined engine inputs; build the device engines first." >&2
        exit 1
    fi
    engine_args="-DNIGHTPAD_ENGINE_ARCHIVE=$engine_archive -DNIGHTPAD_SDL_LIB=$sdl -DNIGHTPAD_FFMPEG_ROOT=$ffmpeg -DNIGHTPAD_SPIRV_ROOT=$spirv"
fi

SDKROOT=$(xcrun --sdk "$sdk" --show-sdk-path) cmake -S "$repo/apple/ios" -B "$build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 $engine_args >/dev/null
xcodebuild -project "$build/NightPadPlatformProbe.xcodeproj" -scheme NightPadShell \
    -configuration "$configuration" -sdk "$sdk" -arch arm64 CODE_SIGNING_ALLOWED=NO build
