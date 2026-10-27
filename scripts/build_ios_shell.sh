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
build="$repo/build/ios-shell-$lane"

SDKROOT=$(xcrun --sdk "$sdk" --show-sdk-path) cmake -S "$repo/apple/ios" -B "$build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 >/dev/null
xcodebuild -project "$build/NightPadPlatformProbe.xcodeproj" -scheme NightPadShell \
    -configuration Debug -sdk "$sdk" -arch arm64 CODE_SIGNING_ALLOWED=NO build
