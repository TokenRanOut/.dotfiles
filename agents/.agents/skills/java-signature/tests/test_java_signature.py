"""Local JDK integration tests with a Maven substitute and no network access."""

import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile


SCRIPT = Path(__file__).resolve().parents[1] / "bin/java-signature.sh"


class JavaSignatureTest(unittest.TestCase):
    def setUp(self):
        for tool in ("javac", "jar", "javap"):
            if not shutil.which(tool):
                self.skipTest(f"Local JDK tool required: {tool}")
        self.temp = tempfile.TemporaryDirectory(prefix="java-signature-test.")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "project with spaces"
        self.project.mkdir()
        (self.project / "pom.xml").write_text("<project/>")
        self.jar = self.root / "dependency.jar"
        self.compile_class(
            "Api", "public void dependencyMethod() {} private void secret() {} "
            "protected void protectedMethod() {} void packageMethod() {}",
            self.root / "dependency-classes",
        )
        subprocess.run(
            ["jar", "cf", str(self.jar), "-C", str(self.root / "dependency-classes"), "."],
            check=True, capture_output=True,
        )
        self.compile_class("Api", "public void projectMethod() {}", self.project / "target/classes")
        self.compile_class("ProjectOnly", "public void localMethod() {}", self.project / "target/classes")
        maven_bin = self.root / "maven/bin"
        maven_bin.mkdir(parents=True)
        mvn = maven_bin / "mvn"
        mvn.write_text(
            '#!/bin/bash\nset -eu\n'
            '[[ "$PWD" == "$EXPECTED_PROJECT" ]]\n'
            'echo call >> "$MAVEN_CALLS"\n'
            'for arg in "$@"; do\n'
            '  case "$arg" in\n'
            '    -Dmdep.outputFile=*) printf "%s" "$DEPENDENCY_JAR" > "${arg#*=}" ;;\n'
            '  esac\ndone\n'
        )
        mvn.chmod(0o755)
        self.env = dict(os.environ, XDG_CACHE_HOME=str(self.root / "cache"),
                        MAVEN_HOME=str(maven_bin.parent), DEPENDENCY_JAR=str(self.jar),
                        MAVEN_CALLS=str(self.root / "maven-calls"),
                        EXPECTED_PROJECT=str(self.project.resolve()))

    def compile_class(self, name, members, destination):
        source = self.root / f"{name}.java"
        source.write_text(f"package example; public class {name} {{ {members} }}")
        destination.mkdir(parents=True, exist_ok=True)
        subprocess.run(["javac", "-d", str(destination), str(source)],
                       check=True, capture_output=True)

    def run_class(self, name):
        return subprocess.run(
            [str(SCRIPT), "class", name, "--project", str(self.project)],
            cwd=self.project, env=self.env, text=True, capture_output=True,
        )

    def jar_cache(self):
        digest = hashlib.md5(self.jar.read_bytes()).hexdigest()
        return self.root / "cache/java-signature/jars" / digest

    def test_public_signatures_cache_and_project_shadowing(self):
        old_cache = self.jar_cache() / "signatures/example.Api.javap"
        old_cache.parent.mkdir(parents=True)
        old_cache.write_text("private void oldPrivateCache();")

        result = self.run_class("example.Api.class")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("public void dependencyMethod();", result.stdout)
        self.assertIn("descriptor: ()V", result.stdout)
        for hidden in ("secret", "protectedMethod", "packageMethod", "projectMethod", "oldPrivateCache"):
            self.assertNotIn(hidden, result.stdout)

        cache = self.jar_cache() / "signatures-public-v1/example.Api.javap"
        self.assertEqual(cache.read_text(), result.stdout)
        timestamp = cache.stat().st_mtime_ns
        repeated = self.run_class("example.Api")
        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        self.assertEqual(repeated.stdout, result.stdout)
        self.assertEqual(cache.stat().st_mtime_ns, timestamp)
        self.assertEqual((self.root / "maven-calls").read_text(), "call\n")

        # Changed jar contents must use a new signature cache.
        with zipfile.ZipFile(self.jar, "a") as archive:
            archive.writestr("cache-version.txt", "changed")
        changed = self.run_class("example.Api")
        self.assertEqual(changed.returncode, 0, changed.stderr)
        new_cache = self.jar_cache() / "signatures-public-v1/example.Api.javap"
        self.assertNotEqual(cache, new_cache)
        self.assertEqual(new_cache.read_text(), changed.stdout)

    def test_project_only_class_is_rejected(self):
        result = self.run_class("example.ProjectOnly")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Class not found in Maven dependencies", result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertFalse((self.root / "cache/java-signature/classes").exists())

    def run_list(self, project=None, refresh=False):
        args = [str(SCRIPT), "list", "--project", str(project or self.project)]
        if refresh:
            args.append("--refresh")
        result = subprocess.run(args, env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def test_identical_poms_in_different_directories_are_isolated(self):
        self.assertEqual(self.run_list(), str(self.jar))
        other_project = self.root / "other project"
        other_project.mkdir()
        shutil.copyfile(self.project / "pom.xml", other_project / "pom.xml")
        other_jar = self.root / "other.jar"
        shutil.copyfile(self.jar, other_jar)
        self.env.update(EXPECTED_PROJECT=str(other_project.resolve()), DEPENDENCY_JAR=str(other_jar))
        self.assertEqual(self.run_list(other_project), str(other_jar))
        self.assertEqual(self.run_list(), str(self.jar))
        self.assertEqual((self.root / "maven-calls").read_text(), "call\ncall\n")

    def test_refresh_rebuilds_classpath_and_alias_reuses_cache(self):
        self.assertEqual(self.run_list(), str(self.jar))
        alias = self.root / "project alias"
        alias.symlink_to(self.project, target_is_directory=True)
        self.assertEqual(self.run_list(alias / ".." / alias.name), str(self.jar))
        changed_jar = self.root / "updated.jar"
        shutil.copyfile(self.jar, changed_jar)
        self.env["DEPENDENCY_JAR"] = str(changed_jar)
        self.assertEqual(self.run_list(), str(self.jar))
        self.assertEqual((self.root / "maven-calls").read_text(), "call\n")
        self.assertEqual(self.run_list(alias, refresh=True), str(changed_jar))
        self.assertEqual(self.run_list(), str(changed_jar))
        self.assertEqual((self.root / "maven-calls").read_text(), "call\ncall\n")

    def test_selected_pom_change_rebuilds_classpath(self):
        self.assertEqual(self.run_list(), str(self.jar))
        (self.project / "pom.xml").write_text("<project><!-- changed --></project>")
        self.assertEqual(self.run_list(), str(self.jar))
        self.assertEqual((self.root / "maven-calls").read_text(), "call\ncall\n")


class SyntaxTest(unittest.TestCase):
    def test_help(self):
        result = subprocess.run([str(SCRIPT), "--help"], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--refresh", result.stdout)

    def test_bash_syntax(self):
        subprocess.run(["bash", "-n", str(SCRIPT)], check=True)


if __name__ == "__main__":
    unittest.main()
