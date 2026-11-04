#!/usr/bin/env python3
"""Validate an owner-supplied Xbox disc image and stage it without modifying it."""

import argparse
import hashlib
import json
import os
import posixpath
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ENTRY = re.compile(r"^/(.*?) \((\d+) bytes\)$")
REQUIRED_FILES = ("default.xbe", "Driving.xbe")
REQUIRED_DIRS = ("eurocom", "driving")


def fail(message):
    raise SystemExit("prepare_game_data: " + message)


def sha256_file(path, chunk_size=8 * 1024 * 1024):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            block = handle.read(chunk_size)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def xbe_identity(path):
    with path.open("rb") as handle:
        header = handle.read(0x400)
    if header[:4] != b"XBEH" or len(header) < 0x200:
        raise ValueError("not an XBE image: %s" % path)
    base = struct.unpack_from("<I", header, 0x104)[0]
    certificate_word = struct.unpack_from("<I", header, 0x118)[0]
    certificate = certificate_word - base
    if certificate < 0 or certificate + 0xb0 > len(header):
        raise ValueError("XBE certificate is out of bounds")
    title = header[certificate + 0xc:certificate + 0x5c].decode(
        "utf-16le", "replace").split("\0", 1)[0]
    return {
        "sha256": sha256_file(path),
        "bytes": path.stat().st_size,
        "title_id": "0x%08x" % struct.unpack_from("<I", header, certificate + 8)[0],
        "title_name": title,
        "region_mask": "0x%08x" % struct.unpack_from("<I", header, certificate + 0xa0)[0],
        "allowed_media": "0x%08x" % struct.unpack_from("<I", header, certificate + 0x9c)[0],
        "disk_number": struct.unpack_from("<I", header, certificate + 0xa8)[0],
        "version": struct.unpack_from("<I", header, certificate + 0xac)[0],
    }


def parse_listing(output):
    entries = {}
    directories = set()
    case_folded = {}
    for line in output.splitlines():
        match = ENTRY.match(line)
        if not match:
            continue
        raw_name, raw_size = match.groups()
        is_directory = raw_name.endswith("/")
        if is_directory:
            raw_name = raw_name[:-1]
        if not raw_name or "\\" in raw_name or "\x00" in raw_name:
            fail("unsafe archive name: %r" % raw_name)
        if raw_name.startswith("/") or any(part == ".." for part in raw_name.split("/")):
            fail("archive path escapes extraction root: %r" % raw_name)
        name = posixpath.normpath(raw_name)
        if name in (".", "") or name.startswith("../"):
            fail("invalid archive path: %r" % raw_name)
        folded = name.casefold()
        if folded in case_folded:
            fail("case-colliding archive paths: %r and %r" % (case_folded[folded], name))
        case_folded[folded] = name
        if is_directory:
            if int(raw_size) != 0:
                fail("directory listing has nonzero size: %r" % raw_name)
            directories.add(name)
            entries.pop(name, None)
        else:
            if name in directories:
                fail("path is listed as both a file and directory: %r" % name)
            entries[name] = int(raw_size)
    return entries, directories


def validate_tree(root, entries, directories):
    root = root.resolve()
    actual = {}
    symlinks = []
    for current, dirs, files in os.walk(root, followlinks=False):
        current_path = Path(current)
        for name in list(dirs):
            candidate = current_path / name
            if candidate.is_symlink():
                symlinks.append(str(candidate.relative_to(root)))
        for name in files:
            candidate = current_path / name
            if candidate.is_symlink():
                symlinks.append(str(candidate.relative_to(root)))
                continue
            resolved = candidate.resolve()
            if root not in resolved.parents:
                fail("extracted file escaped staging root: %s" % candidate)
            actual[candidate.relative_to(root).as_posix()] = candidate.stat().st_size
    if symlinks:
        fail("extractor produced symbolic links: %s" % ", ".join(symlinks[:5]))
    missing = sorted(set(entries) - set(actual))
    extra = sorted(set(actual) - set(entries))
    mismatched = sorted(name for name in set(entries) & set(actual) if entries[name] != actual[name])
    if missing or extra or mismatched:
        fail("extracted tree differs from listing (missing=%d extra=%d mismatched=%d)" %
             (len(missing), len(extra), len(mismatched)))
    for name in REQUIRED_FILES:
        if name not in actual:
            fail("required file missing: %s" % name)
    for name in set(REQUIRED_DIRS) | directories:
        if not (root / name).is_dir():
            fail("required directory missing: %s" % name)
    return actual


def main():
    repo = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser()
    parser.add_argument("--iso", required=True, type=Path)
    parser.add_argument("--output-root", type=Path, default=repo / "build" / "data")
    parser.add_argument("--extractor", type=Path,
                        default=repo / "tools" / "extract-xiso" / "build" / "extract-xiso")
    args = parser.parse_args()

    iso = args.iso.resolve()
    if not iso.is_file():
        fail("ISO not found: %s" % iso)
    if not args.extractor.is_file():
        fail("extractor not built: %s" % args.extractor)

    source_size = iso.stat().st_size
    source_hash_before = sha256_file(iso)
    listed = subprocess.run([str(args.extractor), "-l", str(iso)], check=True,
                            text=True, stdout=subprocess.PIPE).stdout
    entries, directories = parse_listing(listed)
    if not entries:
        fail("image listing contained no files")
    listed_bytes = sum(entries.values())
    if listed_bytes > source_size:
        fail("declared file sizes exceed the source image")

    args.output_root.mkdir(parents=True, exist_ok=True)
    free = shutil.disk_usage(args.output_root).free
    reserve = listed_bytes // 10 + 512 * 1024 * 1024
    if free < listed_bytes + reserve:
        fail("not enough free space for extraction plus reserve")

    staging = Path(tempfile.mkdtemp(prefix="staging-%s-" % source_hash_before[:12],
                                    dir=str(args.output_root)))
    try:
        print("Extracting %s into guarded staging" % iso, file=sys.stderr)
        # BSD getopt stops at the first operand, so options must precede the ISO.
        result = subprocess.run([str(args.extractor), "-d", str(staging), str(iso)],
                                stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        if result.returncode:
            fail("extractor failed with status %d: %s" %
                 (result.returncode, result.stderr.strip()[-2000:]))
        actual = validate_tree(staging, entries, directories)
        if sha256_file(iso) != source_hash_before:
            fail("source ISO changed during extraction")
        manifest = {
            "schema_version": 1,
            "kind": "NightPad extracted game data",
            "source": {
                "size": source_size,
                "sha256": source_hash_before,
                "immutable_during_prepare": True,
            },
            "extractor": {
                "version": "2.7.1",
                "revision": "3f5b62cfe68f000b0e3c8a30104973f3a297948e",
                "mode": "extract",
            },
            "extracted": {
                "size": sum(actual.values()),
                "file_count": len(actual),
                "files": {name: actual[name] for name in sorted(actual)},
            },
            "executables": {
                name: xbe_identity(staging / name) for name in REQUIRED_FILES
            },
            "required_present": list(REQUIRED_DIRS) + list(REQUIRED_FILES),
        }
        identity = "data-" + source_hash_before[:20]
        target = args.output_root / identity
        if target.exists():
            existing = target / "manifest.json"
            if not existing.is_file():
                fail("content-addressed target exists without a manifest: %s" % target)
            old = json.loads(existing.read_text())
            if old.get("source", {}).get("sha256") != source_hash_before:
                fail("content-addressed target has a different source identity")
            if "executables" not in old:
                old["executables"] = {
                    name: xbe_identity(target / name) for name in REQUIRED_FILES
                }
                existing.write_text(json.dumps(old, indent=2, sort_keys=True) + "\n")
            shutil.rmtree(staging)
        else:
            manifest_path = staging / "manifest.json"
            manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
            os.replace(staging, target)
        pointer = {
            "identity": identity,
            "path": str(target),
            "source_sha256": source_hash_before,
            "manifest": str(target / "manifest.json"),
            "activated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        }
        (args.output_root / "current.json").write_text(
            json.dumps(pointer, indent=2, sort_keys=True) + "\n")
        print(json.dumps(pointer, indent=2, sort_keys=True))
    except BaseException:
        if staging.exists():
            shutil.rmtree(staging, ignore_errors=True)
        raise


if __name__ == "__main__":
    main()

