#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
lane=simulator
if [ $# -gt 0 ]; then
    lane=$1
fi
case "$lane" in
    simulator) sdk=iphonesimulator ;;
    device) sdk=iphoneos ;;
    *) echo "usage: $0 [simulator|device]" >&2; exit 2 ;;
esac

ffmpeg="$repo/build/deps/ffmpeg-ios-$lane"
build="$repo/build/nightfire-ios-$lane"
if [ ! -f "$ffmpeg/lib/libavcodec.a" ]; then
    echo "Missing $ffmpeg; run scripts/build_ffmpeg_ios.sh $lane" >&2
    exit 1
fi

SDKROOT=$(xcrun --sdk "$sdk" --show-sdk-path) cmake -S "$repo/vendor/nightfire" -B "$build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 -DCMAKE_BUILD_TYPE=Release \
    -DNIGHTFIRE_SDL=ON -DNIGHTFIRE_GFX=sdlgpu -DNIGHTFIRE_WINDOW_BASE=0x100000000 \
    -DNF_FFMPEG_LIB_DIR= -DNF_FFMPEG_STATIC_LIB_DIR="$ffmpeg/lib"

"$repo/scripts/patch_ios_sdl.sh" "$lane"

for target in action_standalone driving_standalone; do
    xcodebuild -project "$build/nightfiRE.xcodeproj" -target "$target" -configuration Release \
        -sdk "$sdk" -arch arm64 CODE_SIGNING_ALLOWED=NO build
done

for app in action_standalone driving_standalone; do
    if find "$build/Release-$sdk/$app.app" -maxdepth 1 -name '*.dylib' -print -quit | grep -q .; then
        echo "$app.app contains a loose dylib" >&2
        exit 1
    fi
done
printf '%s\n' "Both engines built for $lane with static SDL and FFmpeg."

