#!/usr/bin/env python3
"""Summarise Nightfire PerfLog lines into stable JSON for a performance record."""

import argparse
import json
import re
import statistics
import sys
from pathlib import Path

LINE = re.compile(
    r"\[perf\] (?P<fps>[0-9.]+) fps \(asked for (?P<asked>[0-9]+)\), "
    r"(?P<working>[0-9.]+) ms working \+ (?P<waiting>[0-9.]+) ms waiting per frame"
)


def summarise(text, skip=0):
    fps, working, waiting = [], [], []
    asked = set()
    for line in text.splitlines():
        match = LINE.search(line)
        if not match:
            continue
        fps.append(float(match.group("fps")))
        working.append(float(match.group("working")))
        waiting.append(float(match.group("waiting")))
        asked.add(int(match.group("asked")))
    if skip > 0:
        fps, working, waiting = fps[skip:], working[skip:], waiting[skip:]
    if not fps:
        return None
    return {
        "samples": len(fps),
        "asked_fps": sorted(asked),
        "fps": {
            "mean": round(statistics.fmean(fps), 2),
            "median": round(statistics.median(fps), 2),
            "min": round(min(fps), 2),
            "max": round(max(fps), 2),
        },
        "working_ms": {
            "mean": round(statistics.fmean(working), 2),
            "median": round(statistics.median(working), 2),
            "max": round(max(working), 2),
        },
        "waiting_ms": {
            "mean": round(statistics.fmean(waiting), 2),
            "max": round(max(waiting), 2),
        },
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("logs", nargs="+", type=Path)
    parser.add_argument("--label", help="route label to carry in the record")
    parser.add_argument("--skip", type=int, default=0, help="drop the first N samples (loading)")
    args = parser.parse_args()
    records, missing = [], []
    for path in args.logs:
        text = path.read_text(errors="replace") if path.is_file() else ""
        summary = summarise(text, args.skip)
        if summary is None:
            missing.append(str(path))
            continue
        summary["log"] = str(path)
        if args.label:
            summary["route"] = args.label
        records.append(summary)
    result = {"runs": records, "missing": missing}
    print(json.dumps(result, indent=2))
    if missing:
        print("summarize_perf: no PerfLog samples in " + ", ".join(missing), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
