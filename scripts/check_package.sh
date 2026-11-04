#!/bin/sh
set -eu

# Checks the unsigned package from scripts/package_device_app.sh: one arm64
# app, only system libraries, and the bundle keys NightPad relies on.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ipa="$repo/build/package/NightPadShell-unsigned.ipa"
if [ ! -f "$ipa" ]; then
    echo "check_package: $ipa is missing; run scripts/package_device_app.sh first" >&2
    exit 1
fi

work=$(mktemp -d /tmp/nightpad-package-check.XXXXXX)
cleanup() { python3 - "$work" <<'PY'
import shutil, sys
shutil.rmtree(sys.argv[1], ignore_errors=True)
PY
}
trap cleanup EXIT INT TERM

unzip -q "$ipa" -d "$work"
app="$work/Payload/NightPadShell.app"
[ -d "$app" ] || { echo "check_package: no Payload/NightPadShell.app" >&2; exit 1; }
[ -x "$app/NightPadShell" ] || { echo "check_package: no executable" >&2; exit 1; }

# Only the executable, its plists and the compiled app icon belong here; game
# data, frameworks or loose libraries must never be packaged.
unexpected=$(find "$app" -mindepth 1 -maxdepth 1 | while read -r entry; do
    case "$(basename "$entry")" in
        (NightPadShell|Info.plist|PkgInfo|Assets.car|AppIcon*.png) ;;
        (*) echo "$entry" ;;
    esac
done)
[ -z "$unexpected" ] || { echo "check_package: unexpected app contents:" >&2; echo "$unexpected" >&2; exit 1; }
[ -f "$app/Assets.car" ] || { echo "check_package: no compiled app icon (Assets.car)" >&2; exit 1; }

arch=$(lipo -info "$app/NightPadShell")
case "$arch" in
    *arm64*) ;;
    *) echo "check_package: not arm64: $arch" >&2; exit 1 ;;
esac

foreign=$(otool -L "$app/NightPadShell" | tail -n +2 | awk '{print $1}' |
    grep -v -E '^(/System/Library/|/usr/lib/|@)' || true)
[ -z "$foreign" ] || { echo "check_package: links non-system libraries:" >&2; echo "$foreign" >&2; exit 1; }

plist="$app/Info.plist"
[ "$(plutil -extract MinimumOSVersion raw "$plist")" = "16.0" ] || { echo "check_package: minimum OS changed" >&2; exit 1; }
[ "$(plutil -extract UIFileSharingEnabled raw "$plist")" = "true" ] || { echo "check_package: file sharing off" >&2; exit 1; }
plutil -extract UISupportedInterfaceOrientations json -o - "$plist" | grep -q Portrait &&
    { echo "check_package: portrait is allowed" >&2; exit 1; } || true

echo "package check: PASS (arm64, system libraries only, landscape, file sharing on)"
