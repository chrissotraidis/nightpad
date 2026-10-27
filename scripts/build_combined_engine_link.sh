#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build="$repo/build/nightfire-ios-device"
project="$build/nightfiRE.xcodeproj"
out="$repo/build/ios-combined"
mkdir -p "$out"

if [ ! -d "$project" ]; then
    echo "Configure the pinned engine for iPhoneOS first." >&2
    exit 1
fi

for target in action_standalone driving_standalone; do
    xcodebuild -project "$project" -target "$target" -configuration Release \
        -sdk iphoneos -arch arm64 CODE_SIGNING_ALLOWED=NO build \
        > "$out/$target.log" 2>&1
done

for app in action_standalone driving_standalone; do
    if find "$build/Release-iphoneos/$app.app" -maxdepth 1 -name '*.dylib' -print -quit | grep -q .; then
        echo "$app.app contains a loose dylib; clean the bundle before accepting the static link" >&2
        exit 1
    fi
done

action_dir="$build/build/action_standalone.build/Release-iphoneos/Objects-normal/arm64"
driving_dir="$build/build/driving_standalone.build/Release-iphoneos/Objects-normal/arm64"
find "$action_dir" -name '*.o' ! -name 'StandaloneMain.o' | sort > "$out/action-objects.txt"
find "$driving_dir" -name '*.o' ! -name 'StandaloneMain.o' | sort > "$out/driving-objects.txt"

sdk=$(xcrun --sdk iphoneos --show-sdk-path)
common="-target arm64-apple-ios16.0 -isysroot $sdk -std=gnu++20 -ffp-contract=off -fms-extensions -fno-exceptions -Wno-ignored-attributes -DNIGHTFIRE_STANDALONE=1 -DNIGHTFIRE_SDL=1 -DNIGHTFIRE_WINDOW_BASE=0x100000000 -I $repo/vendor/nightfire/src"
# shellcheck disable=SC2086
clang++ $common -c "$repo/apple/shared/NightPadActionEngineEntry.cpp" -o "$out/action-entry.o"
# shellcheck disable=SC2086
clang++ $common -c "$repo/apple/shared/NightPadDrivingEngineEntry.cpp" -o "$out/driving-entry.o"

ld -r -arch arm64 -platform_version ios 16.0 26.5 -o "$out/action-raw.o" \
    -filelist "$out/action-objects.txt" "$out/action-entry.o"
ld -r -arch arm64 -platform_version ios 16.0 26.5 -o "$out/driving-raw.o" \
    -filelist "$out/driving-objects.txt" "$out/driving-entry.o"
printf '_NightPadActionEngineThread\n_NightPadActionEngineSetLaunchRequestCallback\n' > "$out/action-exports.txt"
printf '_NightPadDrivingEngineThread\n_NightPadDrivingEngineSetLaunchRequestCallback\n' > "$out/driving-exports.txt"
nmedit -s "$out/action-exports.txt" -o "$out/action-isolated.o" "$out/action-raw.o"
nmedit -s "$out/driving-exports.txt" -o "$out/driving-isolated.o" "$out/driving-raw.o"

spirv="$build/_deps/spirv_cross-build/Release-iphoneos"
sdl="$build/_deps/sdl3-build/Release-iphoneos/libSDL3.a"
ffmpeg="$repo/build/deps/ffmpeg-ios-device/lib"
clang++ -target arm64-apple-ios16.0 -isysroot "$sdk" \
    -c "$repo/tests/ios/NightPadEngineLinkProbe.cpp" -o "$out/link-probe-main.o"
clang++ -target arm64-apple-ios16.0 -isysroot "$sdk" -Wl,-no_fixup_chains \
    -o "$out/nightpad-combined-link" \
    "$out/link-probe-main.o" "$out/action-isolated.o" "$out/driving-isolated.o" "$sdl" \
    "$ffmpeg/libavformat.a" "$ffmpeg/libavcodec.a" "$ffmpeg/libavutil.a" \
    "$spirv/libspirv-cross-msl.a" "$spirv/libspirv-cross-glsl.a" \
    "$spirv/libspirv-cross-core.a" -fobjc-link-runtime -lm \
    -framework CoreMedia -framework CoreVideo -framework CoreAudio -framework AudioToolbox \
    -framework AVFoundation -framework CoreBluetooth -framework CoreGraphics \
    -framework CoreMotion -framework Foundation -framework GameController \
    -framework Metal -framework OpenGLES -framework QuartzCore -framework UIKit \
    -weak_framework CoreHaptics 2> "$out/combined-link.log"

exports=$(nm -gU "$out/nightpad-combined-link" | grep -c 'NightPad.*Engine' || true)
if [ "$exports" -ne 4 ]; then
    echo "Expected four engine bridge exports, found $exports" >&2
    exit 1
fi
file "$out/nightpad-combined-link"
nm -gU "$out/nightpad-combined-link" | grep 'NightPad.*Engine'

