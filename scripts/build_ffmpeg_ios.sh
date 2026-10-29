#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$repo/vendor/nightfire/third_party/ffmpeg"
lanes="simulator device"
if [ $# -gt 0 ]; then
    lanes=$1
fi
common="--enable-static --disable-shared --disable-programs --disable-doc --disable-network --disable-autodetect --disable-everything --enable-protocol=file --enable-demuxer=xmv --enable-decoder=wmv2,adpcm_ima_xbox,adpcm_ima_wav,eamad,adpcm_ea_r1 --disable-avdevice --disable-avfilter --disable-swscale --disable-swresample"

for lane in $lanes; do
    case "$lane" in
        simulator)
            sdk=iphonesimulator
            target=arm64-apple-ios16.0-simulator
            ;;
        device)
            sdk=iphoneos
            target=arm64-apple-ios16.0
            ;;
        *)
            echo "usage: $0 [simulator|device]..." >&2
            exit 2
            ;;
    esac
    prefix="$repo/build/deps/ffmpeg-ios-$lane"
    build="$prefix/build"
    mkdir -p "$build"
    sysroot=$(xcrun --sdk "$sdk" --show-sdk-path)
    (
        cd "$build"
        "$source_dir/configure" --prefix="$prefix" --target-os=darwin --arch=aarch64 \
            --enable-cross-compile --cc=clang --host-cc=clang --sysroot="$sysroot" \
            --extra-cflags="-target $target -ffp-contract=off" \
            --extra-ldflags="-target $target" $common >configure.log 2>&1
        make -j4 >build.log 2>&1
        make install >install.log 2>&1
    )
    lipo -info "$prefix/lib/libavcodec.a"
    printf '%s\n' "Built FFmpeg for $lane at $prefix"
done

