#!/bin/sh
set -eu

# Builds the Release device app and packages it as an unsigned IPA
# (Payload/NightPadShell.app). Signing and installation stay with
# scripts/device_handoff.sh; this is the reproducible artifact recipe.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
"$repo/scripts/build_ios_shell.sh" device release >/dev/null

app="$repo/build/ios-shell-device/Release-iphoneos/NightPadShell.app"
out="$repo/build/package"
ipa="$out/NightPadShell-unsigned.ipa"

python3 - "$out" <<'PY'
import shutil, sys
shutil.rmtree(sys.argv[1], ignore_errors=True)
PY
mkdir -p "$out/Payload"
ditto "$app" "$out/Payload/NightPadShell.app"
(cd "$out" && zip -qry "$ipa" Payload)

if ! unzip -l "$ipa" | grep -q 'Payload/NightPadShell.app/Info.plist'; then
    echo "package: the IPA has no Info.plist" >&2
    exit 1
fi
if unzip -l "$ipa" | grep -q '\.dylib$'; then
    echo "package: the IPA contains a loose dylib" >&2
    exit 1
fi

size=$(du -h "$ipa" | awk '{print $1}')
hash=$(shasum -a 256 "$ipa" | awk '{print $1}')
echo "package: $ipa ($size)"
echo "package: sha256=$hash"
echo "package: unsigned; sign and install with scripts/device_handoff.sh"
