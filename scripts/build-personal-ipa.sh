#!/bin/sh
set -eu

# PadMint's iPhone/iPad recipe. Builds NightPad from a fresh checkout and turns
# the player's own Xbox disc image into the game data folder the app imports.
#   scripts/build-personal-ipa.sh DISC.iso OUTPUT.ipa WORK_DIR
# The unsigned IPA is written to OUTPUT.ipa and the prepared game data folder
# to OUTPUT.ipa.data, which PadMint hands to the player as "NightPad game data".
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ $# -ne 3 ]; then
    echo "usage: $0 DISC.iso OUTPUT.ipa WORK_DIR" >&2
    exit 2
fi
disc=$1
output=$2
work=$3
python=${NIGHTPAD_PYTHON:-python3}
mkdir -p "$work" "$(dirname -- "$output")"

remove_tree() {
    "$python" - "$1" <<'PY'
import shutil, sys
shutil.rmtree(sys.argv[1], ignore_errors=True)
PY
}

echo "NightPad: fetching the pinned sources and applying the engine patches"
"$repo/scripts/bootstrap_dependencies.sh"

# Check the disc before the long build so a wrong image fails in minutes.
echo "NightPad: checking and extracting your disc image (the image is only read)"
prepared="$work/game-data"
"$python" "$repo/scripts/prepare_game_data.py" --iso "$disc" --output-root "$prepared" >/dev/null
folder=$("$python" -c 'import json, sys; print(json.load(open(sys.argv[1]))["path"])' "$prepared/current.json")

echo "NightPad: building FFmpeg, both game engines and the app for iPhone/iPad"
"$repo/scripts/build_ffmpeg_ios.sh" device
"$repo/scripts/build_ios_engines.sh" device
"$repo/scripts/package_device_app.sh"

cp "$repo/build/package/NightPadShell-unsigned.ipa" "$output"
remove_tree "$output.data"
mv "$folder" "$output.data"
echo "NightPad: app $output"
echo "NightPad: game data $output.data"
