import argparse
import importlib.machinery
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / ".script/bin/cookie-sync"
loader = importlib.machinery.SourceFileLoader("cookie_sync", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
cookie_sync = importlib.util.module_from_spec(spec)
loader.exec_module(cookie_sync)


class CookieSyncTest(unittest.TestCase):
    def test_origin_normalization(self):
        self.assertEqual(cookie_sync.parse_storage_origin("https://OP.kmrjdev.cn:443/"),
                         "https://op.kmrjdev.cn")
        self.assertEqual(cookie_sync.parse_storage_origin("http://localhost:8080"),
                         "http://localhost:8080")
        for origin in ["op.kmrjdev.cn", "https://host/path", "https://user:pass@host",
                       "https://host?query", "file:///profile", "https://host:bad"]:
            with self.subTest(origin=origin), self.assertRaises(argparse.ArgumentTypeError):
                cookie_sync.parse_storage_origin(origin)

    def test_latest_record_and_deletion(self):
        def record(key, value, sequence, live=True):
            return SimpleNamespace(script_key=key, value=value,
                                   leveldb_seq_number=sequence, is_live=live)

        records = [record("token", "new", 3), record("token", "old", 1),
                   record("removed", "old", 2), record("removed", "", 4, False),
                   record("empty", "", 5)]
        self.assertEqual(cookie_sync.storage_entries(records),
                         [{"name": "empty", "value": ""}, {"name": "token", "value": "new"}])

    def test_atomic_private_output_and_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "state.json"
            target.write_text("old")
            with patch.object(cookie_sync.os, "replace", side_effect=OSError("test")):
                with self.assertRaises(OSError):
                    cookie_sync.write_private_json(str(target), "new")
            self.assertEqual(target.read_text(), "old")
            self.assertEqual(list(Path(directory).iterdir()), [target])
            cookie_sync.write_private_json(str(target), '{"cookies": []}')
            self.assertEqual(json.loads(target.read_text()), {"cookies": []})
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)

    def test_export_preserves_cookies_and_adds_origins(self):
        args = cookie_sync.build_parser().parse_args([
            "export", "--playwright", "--local-storage-origin", "https://op.kmrjdev.cn",
            "--output", "unused.json",
        ])
        states = [{"origin": "https://op.kmrjdev.cn", "localStorage": []}]
        with patch.object(cookie_sync, "do_export", return_value=[{"name": "test"}]), \
                patch.object(cookie_sync, "export_local_storage", return_value=states) as export, \
                patch.object(cookie_sync, "write_private_json") as write:
            cookie_sync.cmd_export(args)
        export.assert_called_once_with("Default", ["https://op.kmrjdev.cn"])
        self.assertEqual(json.loads(write.call_args.args[1]),
                         {"cookies": [{"name": "test"}], "origins": states})

    def test_origin_requires_playwright_before_reading_credentials(self):
        args = cookie_sync.build_parser().parse_args([
            "export", "--local-storage-origin", "https://op.kmrjdev.cn",
        ])
        with patch.object(cookie_sync, "do_export") as export:
            with self.assertRaises(SystemExit):
                cookie_sync.cmd_export(args)
        export.assert_not_called()

    def test_cookie_only_export_is_unchanged(self):
        args = cookie_sync.build_parser().parse_args(["export", "--output", "unused.json"])
        cookies = [{"name": "test"}]
        with patch.object(cookie_sync, "do_export", return_value=cookies), \
                patch.object(cookie_sync, "export_local_storage") as export, \
                patch.object(cookie_sync, "write_private_json") as write:
            cookie_sync.cmd_export(args)
        export.assert_not_called()
        self.assertEqual(json.loads(write.call_args.args[1]), cookies)

    def test_storage_failure_does_not_replace_output(self):
        args = cookie_sync.build_parser().parse_args([
            "export", "--playwright", "--local-storage-origin", "https://op.kmrjdev.cn",
            "--output", "unused.json",
        ])
        with patch.object(cookie_sync, "do_export", return_value=[]), \
                patch.object(cookie_sync, "export_local_storage", side_effect=SystemExit(1)), \
                patch.object(cookie_sync, "write_private_json") as write:
            with self.assertRaises(SystemExit):
                cookie_sync.cmd_export(args)
        write.assert_not_called()


if __name__ == "__main__":
    unittest.main()
