#!/usr/bin/env python3
"""List and extract the driving/POV control definitions from an EA BIGF .viv."""

import argparse
import json
import struct
from pathlib import Path


def be(data):
    return int.from_bytes(data, "big")


def refpack(packed):
    if len(packed) < 2 or packed[1] != 0xfb:
        return packed
    kind = struct.unpack_from(">H", packed)[0]
    pos = 2
    if kind & 0x8000:
        if kind & 0x100:
            pos += 4
        expected = be(packed[pos:pos + 4])
        pos += 4
    else:
        if kind & 0x100:
            pos += 3
        expected = be(packed[pos:pos + 3])
        pos += 3
    out = bytearray()
    while pos < len(packed):
        command = packed[pos]
        pos += 1
        if not command & 0x80:
            a = packed[pos]
            pos += 1
            literals = command & 3
            offset = ((command & 0x60) << 3) + a + 1
            length = ((command >> 2) & 7) + 3
        elif not command & 0x40:
            a, b = packed[pos], packed[pos + 1]
            pos += 2
            literals = a >> 6
            offset = ((a & 0x3f) << 8) + b + 1
            length = (command & 0x3f) + 4
        elif not command & 0x20:
            a, b, d = packed[pos], packed[pos + 1], packed[pos + 2]
            pos += 3
            literals = command & 3
            offset = ((command & 0x10) << 12) + (a << 8) + b + 1
            length = d + ((command & 0x0c) << 6) + 5
        else:
            literals = ((command & 0x1f) << 2) + 4
            if literals > 0x70:
                count = command & 3
                out.extend(packed[pos:pos + count])
                break
            out.extend(packed[pos:pos + literals])
            pos += literals
            continue
        out.extend(packed[pos:pos + literals])
        pos += literals
        for _ in range(length):
            out.append(out[-offset])
    if not expected or expected != len(out):
        raise ValueError("RefPack length mismatch: expected %d, got %d" % (expected, len(out)))
    return bytes(out)


def parse_bigf(data):
    if data[:4] != b"BIGF":
        raise ValueError("not a BIGF archive")
    directory_size = be(data[0xc:0x10])
    end = directory_size
    footer = data[end - 8:end]
    if len(footer) == 8 and chr(footer[0] | 0x20).isalpha() and footer[1:4].isdigit():
        end -= 8
    entries = {}
    pos = 0x10
    while pos < end:
        offset = be(data[pos:pos + 4])
        size = be(data[pos + 4:pos + 8])
        pos += 8
        nul = data.index(0, pos)
        name = data[pos:nul].decode("cp1252")
        pos = nul + 1
        entries[name.replace(chr(92), "/")] = (offset, size)
    return entries


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--viv", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    data = args.viv.read_bytes()
    entries = parse_bigf(data)
    controls = [(name, value) for name, value in entries.items()
                if name.lower().startswith("data/control/") and value[1]]
    if not any(name.lower() == "data/control/master.def" for name, _ in controls):
        raise SystemExit("inventory_driving_controls: Master.def not found")
    args.output.mkdir(parents=True, exist_ok=True)
    manifest = []
    for name, (offset, size) in sorted(controls):
        packed = data[offset:offset + size]
        unpacked = refpack(packed)
        relative = name.split("/", 2)[2]
        target = args.output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(unpacked)
        manifest.append({
            "name": name,
            "archive_offset": offset,
            "archive_size": size,
            "unpacked_size": len(unpacked),
            "refpack": packed[1:2] == b"\xfb",
        })
    args.output.joinpath("manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"definitions": len(manifest), "output": str(args.output)}, indent=2))


if __name__ == "__main__":
    main()

