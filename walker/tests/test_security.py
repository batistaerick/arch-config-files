import importlib.util
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("security", ROOT / "walker/scripts/actions/system/security.py")
security = importlib.util.module_from_spec(spec)
spec.loader.exec_module(security)


class FidoEnrollmentTests(unittest.TestCase):
    def enroll(self, home, output):
        with patch.object(security.getpass, "getuser", return_value="alice"), \
                patch.object(security.Path, "home", return_value=home), \
                patch.object(security.subprocess, "run", return_value=SimpleNamespace(stdout=output)), \
                patch("builtins.print"):
            security.fido_enroll()
        return (home / ".config/Yubico/u2f_keys").read_text()

    def test_new_key_is_merged_and_duplicate_is_not_repeated(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            self.assertEqual(self.enroll(home, "alice:handle1,key1,es256,+presence\n"),
                             "alice:handle1,key1,es256,+presence\n")
            merged = self.enroll(home, "alice:handle2,key2,es256,+presence\n")
            self.assertEqual(merged, "alice:handle1,key1,es256,+presence:handle2,key2,es256,+presence\n")
            self.assertEqual(self.enroll(home, "alice:handle2,key2,es256,+presence\n"), merged)
            self.assertEqual((home / ".config/Yubico/u2f_keys").stat().st_mode & 0o777, 0o600)

    def test_foreign_or_malformed_registrations_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            with self.assertRaises(ValueError):
                self.enroll(home, "mallory:handle,key\n")
            path = home / ".config/Yubico/u2f_keys"
            path.write_text("bob:handle,key\n")
            with self.assertRaisesRegex(ValueError, "manual review"):
                self.enroll(home, "alice:handle,key\n")
            self.assertEqual(path.read_text(), "bob:handle,key\n")


class PolicyConfirmationTests(unittest.TestCase):
    def test_policy_changes_require_typed_enable(self):
        with tempfile.NamedTemporaryFile() as helper:
            for answer, expected_calls in (("enable", 0), ("", 0), ("ENABLE", 1)):
                with self.subTest(answer=answer), patch.object(security, "ROOT_HELPER", helper.name), \
                        patch("builtins.input", return_value=answer), patch("builtins.print"), \
                        patch.object(security.subprocess, "run") as run:
                    security.main("enable-fido2")
                    self.assertEqual(run.call_count, expected_calls)
                    if expected_calls:
                        run.assert_called_once_with(["sudo", helper.name, "auth-enable", "fido2"], check=True)

    def test_missing_root_helper_never_prompts(self):
        with patch.object(security, "ROOT_HELPER", "/nonexistent/eitr-system"), \
                patch("builtins.input") as prompt, patch.object(security.subprocess, "run") as run:
            with self.assertRaises(RuntimeError):
                security.main("password-only")
            prompt.assert_not_called()
            run.assert_not_called()
