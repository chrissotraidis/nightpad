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


if __name__ == "__main__":
    unittest.main()

