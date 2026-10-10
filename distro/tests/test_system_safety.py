import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("eitr_system", ROOT / "system/eitr-system.py")
system = importlib.util.module_from_spec(spec)
spec.loader.exec_module(system)


class SystemSafetyTests(unittest.TestCase):
    def test_auth_preserves_password_and_account_session_stack(self):
        original = "#%PAM-1.0\nauth include system-auth\naccount include system-auth\nsession include system-auth\n"
        changed = system.pam_with_method(original, "fido2")
        self.assertIn(original, changed)
        self.assertNotIn("nouserok", changed)
        self.assertNotIn("alwaysok", changed)
        self.assertEqual(system.pam_with_method(changed, "password"), original)
        self.assertEqual(system.pam_with_method(changed, "fido2"), changed)

    def test_switching_auth_replaces_only_eitr_owned_line(self):
        original = "auth include login\n"
        changed = system.pam_with_method(system.pam_with_method(original, "fido2"), "fingerprint")
        self.assertNotIn("pam_u2f", changed)
        self.assertIn("pam_fprintd", changed)
        self.assertIn(original, changed)

    def test_non_btrfs_and_separate_package_database_fail_closed(self):
        with patch.object(system, "output", return_value="ext4"):
            with self.assertRaises(RuntimeError): system.snapshot_supported()
        with patch.object(system, "output", return_value="btrfs"), \
                patch.object(system, "mount_source", side_effect=["root", "root", "root", "different"]):
            with self.assertRaises(RuntimeError): system.snapshot_supported()

    def test_snapshot_failure_never_creates_pending_record(self):
        with tempfile.TemporaryDirectory() as temporary, patch.object(system, "STATE", Path(temporary)), \
                patch.object(system, "snapshot_supported", side_effect=RuntimeError("not supported")), \
                patch.object(system, "run") as run:
            with self.assertRaises(RuntimeError): system.snapshot_pre()
            run.assert_not_called()
            self.assertFalse((Path(temporary) / "pending-upgrade.json").exists())

    def test_hooks_abort_updates_if_snapshot_fails(self):
        before = (ROOT / "hooks/05-eitr-snapshot-pre.hook").read_text()
        self.assertIn("Operation = Upgrade", before)
        self.assertIn("When = PreTransaction", before)
        self.assertIn("AbortOnFail", before)
        self.assertIn("/usr/local/lib/eitr/eitr-system snapshot-pre", before)

    def test_auth_targets_are_narrow(self):
        self.assertEqual(system.SERVICES, ("hyprlock", "sddm", "sudo"))
        self.assertNotIn("system-auth", system.SERVICES)
