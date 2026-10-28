#!/bin/sh
set -eu

# Fast gates: host-side logic, both shell builds and the device link contract.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

"$repo/scripts/test_input.sh"
"$repo/scripts/test_touch_layout.sh"
"$repo/scripts/test_touch_input.sh"
"$repo/scripts/test_touch_policy.sh"
"$repo/scripts/test_background_policy.sh"
"$repo/scripts/test_controller_slots.sh"
"$repo/scripts/test_contrast.sh"
"$repo/scripts/test_perf_summary.sh"
"$repo/scripts/test_settings.sh"
"$repo/scripts/test_engine_settings.sh"
"$repo/scripts/test_fmv_audio.sh"
"$repo/scripts/test_presentation.sh"
"$repo/scripts/test_saves_link.sh"
"$repo/scripts/test_engine_save.sh"
"$repo/scripts/test_data_import.sh"
"$repo/scripts/test_data_tools.sh" 2>/dev/null
"$repo/scripts/test_diagnostics.sh"
"$repo/scripts/test_launch_bridge.sh"
"$repo/scripts/build_ios_shell.sh" simulator >/dev/null
"$repo/scripts/build_ios_shell.sh" device >/dev/null
"$repo/scripts/check_ios_shell_link.sh"
"$repo/scripts/verify_patches.sh"
"$repo/scripts/check_privacy.sh"
echo "quick verification: PASS"
