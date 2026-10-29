#!/usr/bin/env python3
"""Run Nightfire action recordings one at a time and preserve their logs."""

import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path


def main():
    repo = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser()
    parser.add_argument("--fast", type=int, default=4)
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--only", action="append", default=[])
    parser.add_argument("--fail-fast", action="store_true")
    parser.add_argument("--demos", type=Path,
                        default=repo / "vendor/nightfire/tests/demos/action")
    parser.add_argument("--exe", type=Path,
                        default=repo / "vendor/nightfire/build/macos-arm64/action_standalone_test")
    parser.add_argument("--disc", type=Path,
                        help="experimental staged data root; defaults to build/data/current.json")
    args = parser.parse_args()

    data_pointer = repo / "build/data/current.json"
    if not data_pointer.is_file():
        raise SystemExit("run_action_demos: game data is not prepared")
    data = Path(args.disc).resolve() if args.disc else Path(
        json.loads(data_pointer.read_text())["path"]).resolve()
    disc = repo / "vendor/nightfire/build/disc"
    if not disc.exists():
        disc.symlink_to(data, target_is_directory=True)
    elif disc.resolve() != data:
        raise SystemExit("run_action_demos: build/disc points at different data")

    demos = sorted(args.demos.glob("*.nfdemo"))
    if args.only:
        demos = [demo for demo in demos if any(name in demo.name for name in args.only)]
    if not demos:
        raise SystemExit("run_action_demos: no recordings selected")

    stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
    evidence = repo / "evidence/action-demos" / stamp
    evidence.mkdir(parents=True, exist_ok=False)
    records = []
    frame_pattern = re.compile(r"playback finished at frame (\d+)")
    for index, demo in enumerate(demos, 1):
        run = evidence / demo.stem
        run.mkdir()
        log_path = run / "run.log"
        env = dict(os.environ)
        env.update({
            "SDL_VIDEO_DRIVER": "offscreen",
            "SDL_AUDIO_DRIVER": "dummy",
            "NIGHTFIRE_DEMO_FAST": str(args.fast),
            "NIGHTFIRE_DEMO_PLAY": str(demo.resolve()),
        })
        started = time.monotonic()
        print("[%d/%d] %s" % (index, len(demos), demo.name), flush=True)
        timed_out = False
        with log_path.open("wb") as log:
            try:
                result = subprocess.run([str(args.exe.resolve())], cwd=run, env=env,
                                        stdout=log, stderr=subprocess.STDOUT,
                                        timeout=args.timeout)
                status = result.returncode
            except subprocess.TimeoutExpired:
                timed_out = True
                status = 124
        text = log_path.read_text(errors="replace")
        match = frame_pattern.search(text)
        passed = status == 0 and "every frame matched the recording" in text and not timed_out
        record = {
            "demo": demo.name,
            "demo_sha256": __import__("hashlib").sha256(demo.read_bytes()).hexdigest(),
            "status": status,
            "timed_out": timed_out,
            "frames": int(match.group(1)) if match else None,
            "seconds": round(time.monotonic() - started, 3),
            "passed": passed,
            "log": str(log_path.relative_to(repo)),
        }
        records.append(record)
        print("  %s, %s frames, %.1fs" %
              ("PASS" if passed else "FAIL", record["frames"], record["seconds"]), flush=True)
        (evidence / "results.json").write_text(json.dumps(records, indent=2) + "\n")
        if not passed and args.fail_fast:
            print(text[-4000:], file=sys.stderr)
            raise SystemExit("run_action_demos: %s failed" % demo.name)

    failures = [record for record in records if not record["passed"]]
    print(json.dumps({
        "recordings": len(records),
        "passed": len(records) - len(failures),
        "failed": len(failures),
        "frames": sum(record["frames"] or 0 for record in records),
        "seconds": round(sum(record["seconds"] for record in records), 3),
        "results": str((evidence / "results.json").relative_to(repo)),
    }, indent=2))
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

