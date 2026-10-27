#!/usr/bin/env python3
'''Inspect a driving track's CARP data without the game.

The track (.crp inside a driving mission archive) is a tree of 16-byte UGroup
records. This reads a document's Map group, lists its data items, and decodes
the mission rules' event lists, which is where objectives, messages and
waypoints are posted. Nothing here is used by the build; it exists so the
campaign inventory can be checked without a run.

    python3 scripts/inspect_driving_track.py build/paris_mis01.crp
    python3 scripts/inspect_driving_track.py track.crp --events 69 235
'''

import argparse
import struct
import sys
from pathlib import Path


def u32(data, offset):
    return struct.unpack_from('<I', data, offset)[0]


def tag_text(tag):
    return ''.join(chr((tag >> shift) & 0xff) for shift in (24, 16, 8, 0))


def items(data, base):
    tag, flags, count, offset = (u32(data, base + k * 4) for k in range(4))
    groups = flags >> 5
    start = base + offset * 16 if flags & 0x02 else offset
    return tag, flags, groups, count, start


def walk(data, base, depth, seen, groups, records):
    if base in seen or depth > 8 or base < 0 or base + 16 > len(data):
        return
    seen.add(base)
    tag, flags, group_count, count, start = items(data, base)
    groups.append((base, tag, flags, group_count, count))
    if start < 0 or start > len(data):
        return
    for i in range(min(group_count, 4096)):
        walk(data, start + i * 16, depth + 1, seen, groups, records)
    for i in range(min(count, 8192)):
        record = start + group_count * 16 + i * 16
        if record + 16 > len(data):
            break
        tag, flags, count, offset = (u32(data, record + k * 4) for k in range(4))
        payload = record + offset if flags & 0x02 else offset
        records.append((record, tag, flags, count, payload))


def find_map(data):
    groups, records = [], []
    walk(data, 0, 0, set(), groups, records)
    for base, tag, _flags, _groups, _count in groups:
        if tag_text(tag) == 'Map ' :
            return base
    return None


def map_items(data, base):
    _tag, _flags, group_count, count, start = items(data, base)
    found = {}
    for i in range(count):
        record = start + group_count * 16 + i * 16
        tag, flags, count, offset = (u32(data, record + k * 4) for k in range(4))
        payload = record + offset if flags & 0x02 else offset
        found.setdefault(tag, (record, flags, count, payload))
    return found


def event_lists(data, map_base):
    'index -> (record, flags, count, payload) for every elNN record'
    _tag, _flags, group_count, count, start = items(data, map_base)
    lists = {}
    for i in range(count):
        record = start + group_count * 16 + i * 16
        tag, flags, count_, offset = (u32(data, record + k * 4) for k in range(4))
        if (tag >> 16) == 0x656C:
            payload = record + offset if flags & 0x02 else offset
            lists[tag & 0xffff] = (record, flags, count_, payload)
    return lists


def events(data, payload):
    count = u32(data, payload)
    out = []
    for i in range(min(count, 256)):
        entry = payload + 16 + i * 16
        if entry + 16 > len(data):
            break
        kind = u32(data, entry)
        target = entry + u32(data, entry + 8)
        out.append((kind, target))
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('crp', type=Path)
    parser.add_argument('--events', type=int, nargs='*', default=[],
                        help='event numbers whose data words to print')
    parser.add_argument('--rules', action='store_true', help='list every rule')
    args = parser.parse_args()
    data = args.crp.read_bytes()
    if u32(data, 0) != 0x43415250:
        raise SystemExit('%s is not a CARP document' % args.crp)
    base = find_map(data)
    if base is None:
        raise SystemExit('no Map group')
    found = map_items(data, base)
    print('map group at 0x%x' % base)
    families = {}
    for tag, (_r, _f, count, payload) in found.items():
        key = tag if (tag & 0xffff) == 0x2020 else tag & 0xffff0000
        entry = families.setdefault(key, [0, payload])
        entry[0] += count
    for tag, (count, payload) in sorted(families.items()):
        label = tag_text(tag)[:4] if (tag & 0xffff) == 0x2020 else tag_text(tag)[:2] + '##'
        print('  %-4s count=%-5d payload=0x%x' % (label, count, payload))
    lists = event_lists(data, base)
    rules = found.get(0x52756C65)  # 'Rule'
    if rules is None:
        return 0
    _record, _flags, count, payload = rules
    counts = {}
    for i in range(count):
        rule = payload + i * 32
        kind, flags, stage = u32(data, rule), u32(data, rule + 4), u32(data, rule + 8)
        reference = u32(data, rule + 12)
        index = reference & 0xffff
        if (reference >> 16) != 0x656C or index not in lists:
            continue
        if args.rules:
            print('rule %d kind=%d flags=%d stage=%d el=%d' % (i, kind, flags, stage, index))
        for event_kind, target in events(data, lists[index][3]):
            counts[event_kind] = counts.get(event_kind, 0) + 1
            if event_kind in args.events:
                words = [u32(data, target + k * 4) for k in range(6)]
                print('  el=%d event=%d words=%s' % (index, event_kind, words))
    print('rule event types:')
    for kind, number in sorted(counts.items(), key=lambda kv: -kv[1]):
        print('  %4d  %d' % (kind, number))
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except BrokenPipeError:
        sys.exit(0)
