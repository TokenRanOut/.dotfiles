import contextlib
import importlib.machinery
import importlib.util
import io
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import call, patch


SCRIPT = Path(__file__).resolve().parents[1] / ".script/bin/opencode-session-cleanup"
loader = importlib.machinery.SourceFileLoader("opencode_session_cleanup", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
cleanup = importlib.util.module_from_spec(spec)
loader.exec_module(cleanup)


def session(identifier, directory="/missing", parent=None):
    value = {"id": identifier, "location": {"directory": directory}, "title": identifier}
    if parent:
        value["parentID"] = parent
    return value


class SessionCleanupTest(unittest.TestCase):
    def test_pagination_encodes_cursor(self):
        first, second = session("ses_1"), session("ses_2")
        with patch.object(cleanup, "api", side_effect=[
            {"data": [first], "cursor": {"next": "a+b/="}},
            {"data": [second], "cursor": {"next": None}},
        ]) as api:
            self.assertEqual(cleanup.list_sessions(), [first, second])
        self.assertEqual(api.call_args_list, [
            call("get", "/api/session?limit=100"),
            call("get", "/api/session?limit=100&cursor=a%2Bb%2F%3D"),
        ])

    def test_repeated_cursor_stops(self):
        with patch.object(cleanup, "api", return_value={"data": [], "cursor": {"next": "same"}}):
            with self.assertRaises(RuntimeError):
                cleanup.list_sessions()

    def test_directory_checks(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertFalse(cleanup.missing_directory(session("ses_1", directory)))
            self.assertTrue(cleanup.missing_directory(session("ses_2", directory + "/absent")))
        with patch.object(cleanup.os, "stat", side_effect=PermissionError("denied")), \
                contextlib.redirect_stderr(io.StringIO()) as errors:
            self.assertFalse(cleanup.missing_directory(session("ses_3")))
        self.assertIn("跳过", errors.getvalue())

    def test_children_deleted_before_parents(self):
        parent = session("ses_parent")
        child = session("ses_child", parent="ses_parent")
        self.assertEqual(cleanup.deletion_order([parent, child], [parent, child]), [child, parent])

    def test_preserves_ancestors_of_non_candidates(self):
        root = session("ses_root")
        parent = session("ses_parent", parent="ses_root")
        child = session("ses_child", "/existing", parent="ses_parent")
        sibling = session("ses_sibling", parent="ses_root")
        self.assertEqual(
            cleanup.deletion_order([root, parent, child, sibling], [root, parent, sibling]),
            [sibling],
        )

    def test_cycle_stops(self):
        sessions = [session("ses_1", parent="ses_2"), session("ses_2", parent="ses_1")]
        with self.assertRaises(RuntimeError):
            cleanup.deletion_order(sessions, sessions)

    def test_default_only_previews(self):
        with patch.object(cleanup, "list_sessions", return_value=[session("ses_1")]), \
                patch.object(cleanup, "missing_directory", return_value=True), \
                patch.object(cleanup, "api") as api, \
                patch("builtins.input") as prompt, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(cleanup.main([]), 0)
        api.assert_not_called()
        prompt.assert_not_called()

    def test_cancel_does_not_delete(self):
        with patch.object(cleanup, "list_sessions", return_value=[session("ses_1")]), \
                patch.object(cleanup, "missing_directory", return_value=True), \
                patch.object(cleanup, "api") as api, \
                patch("builtins.input", return_value="no"), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(cleanup.main(["--delete"]), 0)
        api.assert_not_called()

    def test_confirmed_deletion(self):
        sessions = [session("ses_parent"), session("ses_child", parent="ses_parent")]
        with patch.object(cleanup, "list_sessions", return_value=sessions), \
                patch.object(cleanup, "missing_directory", return_value=True), \
                patch.object(cleanup, "api") as api, \
                patch("builtins.input", return_value="DELETE"), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(cleanup.main(["--delete"]), 0)
        self.assertEqual(api.call_args_list, [
            call("delete", "/api/session/ses_child"),
            call("delete", "/api/session/ses_parent"),
        ])

    def test_changed_directory_aborts(self):
        with patch.object(cleanup, "list_sessions", return_value=[session("ses_1")]), \
                patch.object(cleanup, "missing_directory", side_effect=[True, False]), \
                patch.object(cleanup, "api") as api, \
                patch("builtins.input", return_value="DELETE"), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(RuntimeError):
                cleanup.main(["--delete"])
        api.assert_not_called()

    def test_changed_session_relationship_aborts(self):
        before = [session("ses_1")]
        after = before + [session("ses_new", "/existing", parent="ses_1")]
        with patch.object(cleanup, "list_sessions", side_effect=[before, after]), \
                patch.object(cleanup, "missing_directory", side_effect=[True, True, False]), \
                patch.object(cleanup, "api") as api, \
                patch("builtins.input", return_value="DELETE"), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(RuntimeError):
                cleanup.main(["--delete"])
        api.assert_not_called()

    def test_api_failure_is_reported(self):
        result = subprocess.CompletedProcess([], 1, "", "service unavailable")
        with patch.object(cleanup.subprocess, "run", return_value=result):
            with self.assertRaisesRegex(RuntimeError, "service unavailable"):
                cleanup.api("get", "/api/session")


if __name__ == "__main__":
    unittest.main()
