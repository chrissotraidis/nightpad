#!/bin/sh
set -eu

# Stage NightPad's recipe-only release assets. Nothing is tagged, uploaded or
# published. The assets are the PadMint recipe and its checksum, never an IPA,
# disc image, game data or save.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo"
if [ -n "$(git status --porcelain --untracked-files=normal)" ]; then
    echo "prepare-release: commit or set aside checkout changes first" >&2
    exit 1
fi
version=$(python3 - <<'PY'
import re
text = open("apple/ios/NightPadShellInfo.plist.in").read()
match = re.search(r"<key>CFBundleShortVersionString</key><string>([0-9]+\.[0-9]+\.[0-9]+)</string>", text)
if not match:
    raise SystemExit("prepare-release: no CFBundleShortVersionString")
print(match.group(1))
PY
)
python3 - <<'PY'
import json
recipe = json.load(open("padmint.json"))
assert recipe["id"] == "nightpad", "recipe id"
assert recipe["publication"]["public_binaries"] is False, "public_binaries must stay false"
PY
out="$repo/dist/nightpad-v$version"
mkdir -p "$repo/dist"
# Refuse an existing folder so an old build product can never become an asset.
mkdir "$out"
name="nightpad-v$version-padmint.json"
cp padmint.json "$out/$name"
(cd "$out" && shasum -a 256 "$name" > SHA256SUMS && shasum -a 256 -c SHA256SUMS)
echo "Recipe-only assets: $out"
echo "Audit both files with current PadMint before publishing: python3 -m padmint audit <file>"
