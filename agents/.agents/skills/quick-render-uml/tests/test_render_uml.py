"""Render with the bundled jar without preview, installation, or network access."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SKILL_DIR = Path(__file__).resolve().parents[1]
SCRIPT = SKILL_DIR / "bin/render-uml.sh"
DIAGRAM = "@startuml\nAlice -> Bob: hello\n@enduml\n"


class RenderUmlTest(unittest.TestCase):
    def test_executable_and_syntax(self):
        self.assertTrue(os.access(SCRIPT, os.X_OK))
        subprocess.run(["zsh", "-n", str(SCRIPT)], check=True)

    def test_render_in_caller_temp_root_without_preview(self):
        if not shutil.which("java") or not list((SKILL_DIR / "lib").glob("plantuml-*.jar")):
            self.skipTest("Java and the bundled PlantUML jar are required")
        with tempfile.TemporaryDirectory(prefix="render-uml-test.") as directory:
            root = Path(directory)
            project = root / "project with spaces"
            project.mkdir()
            temp_root = root / "runtime temp"
            temp_root.mkdir()
            tools = root / "bin"
            tools.mkdir()
            # Detect preview calls even if the script ignores their exit status.
            open_mock = tools / "open"
            open_mock.write_text('#!/bin/sh\ntouch "$PREVIEW_MARKER"\n')
            open_mock.chmod(0o755)
            marker = root / "preview-called"
            env = dict(os.environ, TMPDIR=str(temp_root), PREVIEW_MARKER=str(marker),
                       PATH=str(tools) + os.pathsep + os.environ["PATH"])
            source = project / "sequence.puml"
            source.write_text(DIAGRAM)
            for mode, extension in (("file", "svg"), ("stdin", "png")):
                with self.subTest(mode=mode, extension=extension):
                    args = [str(SCRIPT), mode]
                    args += [source.name] if mode == "file" else ["--name", "流程 diagram"]
                    result = subprocess.run(
                        args + [f"--{extension}", "--no-open", "--engine", "jar"],
                        input=DIAGRAM if mode == "stdin" else None,
                        cwd=project, env=env, text=True, capture_output=True, timeout=60,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    output = Path(result.stdout.strip().splitlines()[-1])
                    self.assertTrue(output.is_relative_to(temp_root), output)
                    content = output.read_bytes()
                    if extension == "svg":
                        self.assertIn(b"<svg", content)
                    else:
                        self.assertTrue(content.startswith(b"\x89PNG\r\n\x1a\n"))
            self.assertFalse(marker.exists())
            self.assertEqual(list(project.iterdir()), [source])
            self.assertTrue(list(temp_root.glob("opencode-uml.*/流程 diagram.puml")))

    def test_invalid_names_are_rejected_before_writing(self):
        with tempfile.TemporaryDirectory(prefix="render-uml-names.") as directory:
            root = Path(directory)
            temp_root = root / "runtime"
            temp_root.mkdir()
            sentinel = root / "outside.puml"
            sentinel.write_text("preserve existing content")
            env = dict(os.environ, TMPDIR=str(temp_root))
            names = ("", ".", "..", "../escape", "../../outside", "nested/name",
                     r"..\escape", r"nested\name", str(root / "absolute"))
            for mode in ("stdin", "clipboard"):
                for name in names:
                    with self.subTest(mode=mode, name=name):
                        result = subprocess.run(
                            [str(SCRIPT), mode, "--name", name, "--no-open"],
                            input=DIAGRAM, env=env, text=True, capture_output=True, timeout=10,
                        )
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn("Invalid --name", result.stderr)
                        self.assertEqual(result.stdout, "")
                        self.assertEqual(list(temp_root.iterdir()), [])
                        self.assertEqual(sentinel.read_text(), "preserve existing content")
                        self.assertEqual(set(root.iterdir()), {temp_root, sentinel})

    def test_help(self):
        result = subprocess.run([str(SCRIPT), "--help"], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Single file name", result.stdout)


if __name__ == "__main__":
    unittest.main()
