#!/bin/sh
set -eu

# Builds the device shell and, when a signing identity and a connected device
# are available, installs and launches it. Without either it prints the exact
# remaining prerequisites instead of failing silently.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
install=0
team=""
device=""
bundle="local.nightpad.shell"
for arg in "$@"; do
    case "$arg" in
        --install) install=1 ;;
        --team=*) team=${arg#--team=} ;;
        --device=*) device=${arg#--device=} ;;
        --bundle=*) bundle=${arg#--bundle=} ;;
        -h|--help)
            echo "usage: $0 [--install] [--team=TEAMID] [--device=UDID] [--bundle=ID]"
            exit 0
            ;;
        *) echo "unknown argument: $arg" >&2; exit 2 ;;
    esac
done

echo "NightPad device handoff"
xcodebuild -version | head -1
echo "iPhoneOS SDK: $(xcrun --sdk iphoneos --show-sdk-path)"

valid=$(security find-identity -v -p codesigning 2>/dev/null | sed -n 's/.*\([0-9][0-9]*\) valid identities found.*/\1/p' | head -1)
valid=${valid:-0}
echo "Signing identities: $valid"

devices=$(xcrun devicectl list devices 2>/dev/null | grep -ci 'connected' || true)
echo "Connected devices: $devices"

echo "Building the unsigned device shell..."
"$repo/scripts/build_ios_shell.sh" device >/dev/null
"$repo/scripts/check_ios_shell_link.sh"
app="$repo/build/ios-shell-device/Debug-iphoneos/NightPadShell.app"
echo "Built: $app"

if [ "$install" -eq 0 ]; then
    if [ "$valid" -eq 0 ] || [ "$devices" -eq 0 ]; then
        echo "Install skipped: need a signing identity and a trusted device."
        echo "Run again with --install --team=<TEAMID> once both are present."
    else
        echo "Ready to install. Re-run with --install --team=<TEAMID>."
    fi
    exit 0
fi

if [ "$valid" -eq 0 ]; then
    echo "Cannot install: no valid code-signing identity." >&2
    echo "Open Xcode, sign in with the Apple ID, and add a development team." >&2
    exit 2
fi
if [ "$devices" -eq 0 ]; then
    echo "Cannot install: no connected, trusted device." >&2
    echo "Connect the iPhone or iPad, unlock it, and accept the trust prompt." >&2
    exit 2
fi
if [ -z "$team" ]; then
    echo "Cannot install: pass --team=<TEAMID> (Xcode account team identifier)." >&2
    exit 2
fi

project="$repo/build/ios-shell-device/NightPadPlatformProbe.xcodeproj"
echo "Signing a release build for team $team..."
xcodebuild -project "$project" -scheme NightPadShell -configuration Release \
    -sdk iphoneos -arch arm64 \
    DEVELOPMENT_TEAM="$team" CODE_SIGN_STYLE=Automatic CODE_SIGNING_ALLOWED=YES \
    PRODUCT_BUNDLE_IDENTIFIER="$bundle" -allowProvisioningUpdates build

signed="$repo/build/ios-shell-device/Release-iphoneos/NightPadShell.app"
if [ -z "$device" ]; then
    device=$(xcrun devicectl list devices 2>/dev/null | awk '/connected/ {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-Fa-f-]{8,}$/) {print $i; exit}}')
fi
if [ -z "$device" ]; then
    echo "Cannot install: pass --device=<UDID> (xcrun devicectl list devices)." >&2
    exit 2
fi
echo "Installing on $device..."
xcrun devicectl device install app --device "$device" "$signed"
echo "Launching $bundle (Ctrl-C to stop the console)..."
xcrun devicectl device process launch --device "$device" --console "$bundle"
