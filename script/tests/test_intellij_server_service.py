import hashlib
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import textwrap
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / ".script/bin/intellij-server-service"
loader = importlib.machinery.SourceFileLoader("intellij_server_service", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
service = importlib.util.module_from_spec(spec)
loader.exec_module(service)


class ServiceTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="intellij-service-test-")
        self.root = Path(self.temporary.name).resolve()
        self.state = self.root / "shared state"
        self.binary = self.root / "fake server/bin/intellij-server"
        self.binary.parent.mkdir(parents=True)
        self.eula = self.binary.parent.parent / "EULA.txt"
        self.eula.write_text("Test license, not the JetBrains EULA.\n")
        self.binary.write_text(f"#!{sys.executable}\n" + textwrap.dedent('''
            import argparse
            import signal
            import socket
            import sys
            import time
            parser = argparse.ArgumentParser()
            parser.add_argument("--socket")
            parser.add_argument("--multi-client", action="store_true")
            parser.add_argument("--system-path")
            parser.add_argument("--eula")
            args = parser.parse_args()
            print("eula=" + args.eula, flush=True)
            print("fake server started", flush=True)
            address, port = args.socket.rsplit(":", 1)
            listener = socket.socket()
            listener.bind((address, int(port)))
            listener.listen()
            signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
            while True:
                time.sleep(0.1)
        '''))
        self.binary.chmod(0o700)
        self.router = self.binary.parent / "lsp-router"
        self.router.write_text("#!/bin/sh\nexit 0\n")
        self.router.chmod(0o700)
        with socket.socket() as available:
            available.bind(("127.0.0.1", 0))
            self.port = available.getsockname()[1]

    def tearDown(self):
        self.run_command("stop")
        self.temporary.cleanup()

    def command(self, action, *extra):
        return [
            sys.executable, "-B", str(SCRIPT), action,
            "--server-path", str(self.binary), "--state-dir", str(self.state),
            "--port", str(self.port), "--timeout", "5", *extra,
        ]

    def run_command(self, action, *extra):
        return subprocess.run(
            self.command(action, *extra), capture_output=True, text=True, timeout=15,
        )

    def record(self):
        return json.loads((self.state / "service.json").read_text())

    def test_start_status_logs_stop_and_repeated_start(self):
        result = self.run_command("start")
        self.assertEqual(result.returncode, 0, result.stderr)
        original = self.record()
        self.assertIn("--multi-client", original["identity"])
        self.assertIn(str(self.state / "system"), original["identity"])
        self.assertEqual(self.run_command("start").returncode, 0)
        self.assertEqual(self.record()["pid"], original["pid"])
        self.assertEqual(self.run_command("status").returncode, 0)
        self.assertIn("fake server started", self.run_command("logs").stdout)
        self.assertEqual(self.run_command("stop").returncode, 0)
        self.assertEqual(self.run_command("status").returncode, 1)
        self.assertFalse((self.state / "service.json").exists())

    def test_start_automatically_uses_current_license(self):
        result = self.run_command("start")
        self.assertEqual(result.returncode, 0, result.stderr)
        original_hash = hashlib.sha256(self.eula.read_bytes()).hexdigest()[:16]
        self.assertIn("eula=" + original_hash, self.run_command("logs").stdout)
        self.assertEqual(self.run_command("stop").returncode, 0)
        self.eula.write_text("Changed test license\n")
        self.assertEqual(self.run_command("start").returncode, 0)
        changed_hash = hashlib.sha256(self.eula.read_bytes()).hexdigest()[:16]
        self.assertNotEqual(original_hash, changed_hash)
        self.assertIn("eula=" + changed_hash, self.run_command("logs").stdout)
        self.assertFalse((self.state / "accepted-eula.sha256").exists())

    def test_start_creates_link_and_repeated_start_repairs_it_for_running_version(self):
        self.assertEqual(self.run_command("start").returncode, 0)
        link = self.state / "server"
        self.assertTrue(link.is_symlink())
        self.assertEqual(link.resolve(), self.binary.parent.parent)
        original_pid = self.record()["pid"]
        link.unlink()
        link.symlink_to(self.root / "missing old server")
        result = self.run_command("start", "--server-path", str(self.root / "new server"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.record()["pid"], original_pid)
        self.assertEqual(link.resolve(), self.binary.parent.parent)

    def test_restart_updates_link_to_new_server_version(self):
        self.assertEqual(self.run_command("start").returncode, 0)
        previous_pid = self.record()["pid"]
        new_directory = self.root / "new server version"
        shutil.copytree(self.binary.parent.parent, new_directory)
        new_binary = new_directory / "bin/intellij-server"
        result = self.run_command("restart", "--server-path", str(new_binary))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotEqual(self.record()["pid"], previous_pid)
        self.assertEqual((self.state / "server").resolve(), new_directory)
        self.assertEqual(self.record()["binary"], str(new_binary))

    def test_missing_or_non_executable_router_refuses_start(self):
        for missing in (False, True):
            with self.subTest(missing=missing):
                if missing:
                    self.router.unlink()
                else:
                    self.router.chmod(0o600)
                result = self.run_command("start")
                self.assertEqual(result.returncode, 1)
                self.assertIn("lsp-router", result.stderr)
                self.assertFalse((self.state / "service.json").exists())
                self.assertFalse((self.state / "server").is_symlink())

    def test_server_link_does_not_replace_existing_file_or_directory(self):
        self.state.mkdir()
        link = self.state / "server"
        for directory in (False, True):
            with self.subTest(directory=directory):
                if directory:
                    link.mkdir()
                else:
                    link.write_text("keep this file")
                result = self.run_command("start")
                self.assertEqual(result.returncode, 1)
                self.assertIn("拒绝覆盖", result.stderr)
                self.assertFalse((self.state / "service.json").exists())
                if directory:
                    self.assertTrue(link.is_dir())
                    link.rmdir()
                else:
                    self.assertEqual(link.read_text(), "keep this file")
                    link.unlink()

    def test_restart_automatically_uses_changed_license(self):
        self.assertEqual(self.run_command("start").returncode, 0)
        previous_pid = self.record()["pid"]
        self.eula.write_text("Changed license before restart\n")
        result = self.run_command("restart")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotEqual(self.record()["pid"], previous_pid)
        expected_hash = hashlib.sha256(self.eula.read_bytes()).hexdigest()[:16]
        self.assertIn("eula=" + expected_hash, self.run_command("logs").stdout)

    def test_concurrent_start_launches_only_one_process(self):
        processes = [subprocess.Popen(
            self.command("start"), stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, text=True,
        ) for _ in range(2)]
        for process in processes:
            output, errors = process.communicate(timeout=15)
            self.assertEqual(process.returncode, 0, output + errors)
        log = (self.state / "launcher.log").read_text()
        self.assertEqual(log.count("fake server started"), 1)

    def test_foreign_port_is_not_adopted(self):
        for reuse_address in (False, True):
            with self.subTest(reuse_address=reuse_address), socket.socket() as foreign:
                foreign.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, int(reuse_address))
                foreign.bind(("127.0.0.1", self.port))
                foreign.listen()
                result = self.run_command("start")
                self.assertEqual(result.returncode, 1)
                self.assertIn("不可用", result.stderr)
                self.assertFalse((self.state / "service.json").exists())

    def test_port_check_allows_time_wait_connections(self):
        with socket.socket() as listener, socket.socket() as client:
            listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            listener.bind(("127.0.0.1", self.port))
            listener.listen()
            client.settimeout(5)
            client.connect(("127.0.0.1", self.port))
            connection, _ = listener.accept()
            connection.close()
            self.assertEqual(client.recv(1), b"")

        service.check_port(self.port)
        with socket.socket() as restarted:
            restarted.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            restarted.bind(("127.0.0.1", self.port))
            restarted.listen()

    def test_stale_record_never_signals_reused_pid(self):
        self.state.mkdir()
        service.write_record(self.state, {
            "pid": os.getpid(), "identity": "not the original process",
            "port": self.port, "binary": str(self.binary),
        })
        with patch.object(service.os, "kill") as kill:
            args = type("Args", (), {"timeout": 1})()
            service.stop_service(args, self.state)
            kill.assert_not_called()

    def test_failed_start_preserves_log_and_removes_record(self):
        self.state.mkdir()
        previous_directory = self.root / "previous server"
        (self.state / "server").symlink_to(previous_directory)
        self.binary.write_text(f"#!{sys.executable}\nimport sys\nprint('startup failure', flush=True)\nsys.exit(7)\n")
        result = self.run_command("start")
        self.assertEqual(result.returncode, 1)
        self.assertIn("退出码 7", result.stderr)
        self.assertFalse((self.state / "service.json").exists())
        self.assertIn("startup failure", (self.state / "launcher.log").read_text())
        self.assertEqual((self.state / "server").resolve(), previous_directory)

    def test_start_timeout_terminates_only_launched_process(self):
        self.binary.write_text(f"#!{sys.executable}\nimport time\ntime.sleep(30)\n")
        result = self.run_command("start", "--timeout", "0.2")
        self.assertEqual(result.returncode, 1)
        self.assertIn("超时", result.stderr)
        self.assertFalse((self.state / "service.json").exists())

    def test_invalid_record_refuses_mutation(self):
        self.state.mkdir()
        (self.state / "service.json").write_text("invalid json")
        result = self.run_command("start")
        self.assertEqual(result.returncode, 1)
        self.assertIn("无法读取服务记录", result.stderr)
        (self.state / "service.json").unlink()

    def test_license_command_only_displays_file(self):
        result = self.run_command("eula")
        self.assertEqual(result.returncode, 0)
        self.assertIn("Test license", result.stdout)
        self.assertFalse((self.state / "accepted-eula.sha256").exists())

    def test_server_discovery_sorts_versions_numerically(self):
        for version in ["1.0.9", "1.0.27"]:
            extension = self.root / f".vscode/extensions/jetbrains.intellij-server-{version}-darwin-arm64"
            binary = extension / "server/bin/intellij-server"
            binary.parent.mkdir(parents=True)
            binary.write_text("#!/bin/sh\nexit 0\n")
            binary.chmod(0o700)
            (extension / "package.json").write_text(json.dumps({"version": version}))
        with patch.object(service.Path, "home", return_value=self.root):
            selected = service.find_server()
        self.assertIn("1.0.27", str(selected))

    def test_license_digest_matches_current_file_without_writing_state(self):
        digest = service.eula_hash(self.binary)
        expected = hashlib.sha256(self.eula.read_bytes()).hexdigest()
        self.assertEqual(digest, expected[:16])
        self.assertFalse(self.state.exists())

    def test_missing_license_refuses_start(self):
        self.eula.unlink()
        result = self.run_command("start")
        self.assertEqual(result.returncode, 1)
        self.assertIn("EULA.txt", result.stderr)
        self.assertFalse((self.state / "service.json").exists())

    def test_help_explains_implicit_acceptance(self):
        result = subprocess.run(
            [sys.executable, "-B", str(SCRIPT), "--help"],
            capture_output=True, text=True, timeout=5,
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("启动即表示接受", result.stdout)
        self.assertNotIn("--accept-eula", result.stdout)


if __name__ == "__main__":
    unittest.main()
