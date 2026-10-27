#!/usr/bin/env python3
"""Run the platform probe on exactly one simulator and collect its result."""

import argparse
import json
import subprocess
import time
from pathlib import Path


def simctl(*args, check=True):
    return subprocess.run(["xcrun", "simctl", *args], check=check,
                          text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def main():
    repo = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser()
    parser.add_argument("--udid", default="7D6E5F28-7AAD-4F1F-AFBD-AD11DB486C16")
    parser.add_argument("--wait", type=int, default=180)
    args = parser.parse_args()

    devices = json.loads(simctl("list", "devices", "booted", "--json").stdout)["devices"]
    booted = [device for runtime in devices.values() for device in runtime]
    other = [device for device in booted if device["udid"] != args.udid]
    if other:
        names = ", ".join(device["name"] for device in other)
        raise SystemExit("run_ios_probe: refusing to add a simulator while these are booted: " + names)
    started = not booted
    if started:
        simctl("boot", args.udid)
        simctl("bootstatus", args.udid, "-b")
    app = repo / "build/ios-simulator/Debug-iphonesimulator/NightPadProbe.app"
    if not app.is_dir():
        raise SystemExit("run_ios_probe: build the simulator probe first")
    simctl("install", args.udid, str(app))
    simctl("terminate", args.udid, "local.nightpad.platform-probe", check=False)
    container = simctl("get_app_container", args.udid,
                       "local.nightpad.platform-probe", "data").stdout.strip()
    result_path = Path(container) / "Library/Caches/nightpad-probe-result.json"
    if result_path.exists():
        result_path.unlink()
    simctl("launch", args.udid, "local.nightpad.platform-probe")
    deadline = time.monotonic() + args.wait
    while time.monotonic() < deadline and not result_path.is_file():
        time.sleep(2)
    evidence = repo / "evidence/ios-probe"
    evidence.mkdir(parents=True, exist_ok=True)
    simctl("io", args.udid, "screenshot", str(evidence / "platform-probe-result.png"))
    if not result_path.is_file():
        if started:
            simctl("shutdown", args.udid)
        raise SystemExit("run_ios_probe: result file did not appear")
    result = json.loads(result_path.read_text())
    (evidence / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    simctl("terminate", args.udid, "local.nightpad.platform-probe", check=False)
    if started:
        simctl("shutdown", args.udid)
    raise SystemExit(0 if result.get("passed") else 1)


if __name__ == "__main__":
    main()

