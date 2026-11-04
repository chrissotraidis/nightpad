#!/bin/sh
set -eu

# A release build must identify itself as a performance build in diagnostics.
# Uses one simulator at a time: if any device is already booted, it stops.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
booted=$(xcrun simctl list devices booted | grep -c 'Booted' || true)
if [ "$booted" -ne 0 ]; then
    echo "release diagnostics: a simulator is already booted; shut it down first" >&2
    exit 2
fi

device=$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ {print $2; exit}')
if [ -z "$device" ]; then
    echo "release diagnostics: no iPhone simulator available" >&2
    exit 2
fi

"$repo/scripts/build_ios_shell.sh" simulator release >/dev/null
app="$repo/build/ios-shell-simulator/Release-iphonesimulator/NightPadShell.app"

cleanup() {
    xcrun simctl terminate "$device" com.chrissotraidis.nightpad >/dev/null 2>&1 || true
    xcrun simctl shutdown "$device" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

xcrun simctl boot "$device" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$device" -b >/dev/null 2>&1
xcrun simctl install "$device" "$app"
xcrun simctl launch "$device" com.chrissotraidis.nightpad --open-diagnostics >/dev/null
sleep 4

container=$(xcrun simctl get_app_container "$device" com.chrissotraidis.nightpad data)
report=$(ls -t "$container"/Library/Logs/NightPad/*.txt | head -1)
if ! grep -q 'build_configuration=performance/release' "$report"; then
    echo "release diagnostics: report does not identify a performance build" >&2
    grep 'build_configuration' "$report" >&2 || true
    exit 1
fi
grep -q 'session_event=' "$report"
echo "release diagnostics: PASS (performance/release report from a release build)"
