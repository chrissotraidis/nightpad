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
build="$repo/build/ios-$lane"
ffmpeg="$repo/build/deps/ffmpeg-ios-$lane"
if [ ! -f "$ffmpeg/lib/libavcodec.a" ]; then
    echo "Missing $ffmpeg; run scripts/build_ffmpeg_ios.sh $lane" >&2
    exit 1
fi

fixture=""
if [ -f "$repo/build/data/current.json" ]; then
    data=$(cd "$repo" && python3 -c 'import json; print(json.load(open("build/data/current.json"))["path"])')
    if [ -n "$data" ]; then
        candidate="$data/eurocom/30_fps/07100001.xmv"
        if [ -f "$candidate" ]; then
            mkdir -p "$repo/build/fixtures"
            cp "$candidate" "$repo/build/fixtures/fixture.xmv"
            fixture="$repo/build/fixtures/fixture.xmv"
        fi
    fi
fi

SDKROOT=$(xcrun --sdk "$sdk" --show-sdk-path) cmake -S "$repo/apple/ios" -B "$build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 -DNIGHTPAD_FFMPEG_ROOT="$ffmpeg" \
    -DNIGHTPAD_MEDIA_FIXTURE="$fixture"
xcodebuild -project "$build/NightPadPlatformProbe.xcodeproj" -scheme NightPadProbe \
    -configuration Debug -sdk "$sdk" -arch arm64 CODE_SIGNING_ALLOWED=NO build

