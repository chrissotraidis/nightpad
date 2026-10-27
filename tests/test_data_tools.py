import importlib.util
import struct
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def load(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


prepare = load("nightpad_prepare", "scripts/prepare_game_data.py")
controls = load("nightpad_controls", "scripts/inventory_driving_controls.py")
track = load("nightpad_track", "scripts/inspect_driving_track.py")


def carp_document():
    """A minimal CARP: root -> Map -> one Rule and one elNN event list."""
    data = bytearray(0x400)

    def put(offset, value):
        struct.pack_into("<I", data, offset, value)

    def group(offset, tag, flags, count, data_word):
        put(offset, tag)
        put(offset + 4, flags)
        put(offset + 8, count)
        put(offset + 12, data_word)

    # root: one subgroup ('Map ') at +0x10, no data items
    group(0x00, 0x43415250, (1 << 5) | 0x02, 0, 1)
    # Map group: two data items at 0x100, no subgroups
    group(0x10, 0x4D617020, 0x02, 2, 0x0F)
    # items: Rule, then el 1
    group(0x100, 0x52756C65, 0x02, 1, 0x100)          # payload at 0x200
    group(0x110, 0x656C0001, 0x02, 1, 0x130)          # payload at 0x240
    # one rule: kind 3, enabled, every stage, events = el 1
    group(0x200, 3, 1, 0, 0x656C0001)
    # event list: one event, its data at +0x20
    put(0x240, 1)
    put(0x250, 69)
    put(0x258, 0x20)
    # the objective record: type, symbol reference, empty fields, no comment
    put(0x270, 69)
    put(0x274, 0x73720001)
    return bytes(data)


class PrepareListingTests(unittest.TestCase):
    def test_splits_files_and_directories(self):
        files, directories = prepare.parse_listing(
            "/default.xbe (12 bytes)\n/eurocom/ (0 bytes)\n/eurocom/a.xmv (3 bytes)\n")
        self.assertEqual(files, {"default.xbe": 12, "eurocom/a.xmv": 3})
        self.assertEqual(directories, {"eurocom"})

    def test_rejects_traversal(self):
        with self.assertRaises(SystemExit):
            prepare.parse_listing("/../escape.bin (1 bytes)\n")

    def test_rejects_case_collision(self):
        with self.assertRaises(SystemExit):
            prepare.parse_listing("/A.bin (1 bytes)\n/a.bin (1 bytes)\n")

    def test_validate_tree_rejects_missing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(SystemExit):
                prepare.validate_tree(Path(directory), {"default.xbe": 1}, set())


class BigFileTests(unittest.TestCase):
    def test_refpack_literal(self):
        # Type 0x10, no optional compressed size, 24-bit unpacked length 4.
        packed = bytes((0x10, 0xFB, 0, 0, 4, 0xE0)) + b"ABCD"
        packed += bytes((0xFC,))
        self.assertEqual(controls.refpack(packed), b"ABCD")

    def test_bigf_directory(self):
        name = b"data\\Control\\Master.def\0"
        directory_size = 0x10 + 8 + len(name)
        header = b"BIGF" + struct.pack(">I", 0) + struct.pack(">I", 1)
        header += struct.pack(">I", directory_size)
        entry = struct.pack(">I", 0x100) + struct.pack(">I", 7) + name
        parsed = controls.parse_bigf(header + entry + b"x" * 0x100)
        self.assertEqual(parsed, {"data/Control/Master.def": (0x100, 7)})


class TrackInspectionTests(unittest.TestCase):
    def test_finds_map_group_and_items(self):
        data = carp_document()
        base = track.find_map(data)
        self.assertEqual(base, 0x10)
        found = track.map_items(data, base)
        self.assertIn(0x52756C65, found)
        self.assertIn(0x656C0001, found)

    def test_decodes_rule_event_list(self):
        data = carp_document()
        lists = track.event_lists(data, track.find_map(data))
        self.assertEqual(list(lists), [1])
        decoded = track.events(data, lists[1][3])
        self.assertEqual([kind for kind, _target in decoded], [69])
        kind, target = decoded[0]
        self.assertEqual(kind, 69)
        self.assertEqual(struct.unpack_from("<I", data, target)[0], 69)


if __name__ == "__main__":
    unittest.main()

