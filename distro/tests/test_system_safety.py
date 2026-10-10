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

    def test_only_system_update_requests_snapshots(self):
        script = (ROOT.parent / "walker/scripts/actions/system/update.sh").read_text()
        protected = script.split("system)")[1].split(";;")[0]
        self.assertIn('sudo "$helper" snapshot-pre', protected)
        self.assertLess(protected.index("snapshot-pre"), protected.index("\n      full_update"))
        self.assertIn('sudo "$helper" snapshot-post', protected)
        self.assertNotIn("snapshot-pre", script.split("pacman)")[1])

    def test_auth_targets_are_narrow(self):
        self.assertEqual(system.SERVICES, ("hyprlock", "sddm", "sudo"))
        self.assertNotIn("system-auth", system.SERVICES)


class Account:
    def __init__(self, home, uid):
        self.pw_dir = str(home)
        self.pw_uid = uid


class SnapshotRecordTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.state = Path(temporary.name)
        patcher = patch.object(system, "STATE", self.state)
        patcher.start()
        self.addCleanup(patcher.stop)

    def write_pending(self, identifier="7"):
        (self.state / "pending-upgrade.json").write_text('{"snapshot": "%s", "boot": ""}\n' % identifier)

    def test_post_records_outcome_and_clears_pending(self):
        self.write_pending()
        with patch.object(system, "run") as run:
            system.snapshot_post("failed")
        command = run.call_args.args[0]
        self.assertEqual(command[command.index("--pre-number") + 1], "7")
        self.assertIn("Eitr after failed package upgrade", command)
        self.assertFalse((self.state / "pending-upgrade.json").exists())

    def test_post_without_pending_record_does_nothing(self):
        with patch.object(system, "run") as run:
            system.snapshot_post()
        run.assert_not_called()

    def test_pre_closes_stale_pending_record_before_new_snapshot(self):
        self.write_pending("3")
        calls = []
        with patch.object(system, "snapshot_supported"), \
                patch.object(system, "separate_boot_mounts", return_value=[]), \
                patch.object(system, "run", side_effect=lambda args, **_: calls.append(args)), \
                patch.object(system, "output", side_effect=lambda args: calls.append(args) or "4"), \
                patch("builtins.print"):
            system.snapshot_pre()
        posts = [call for call in calls if "post" in call]
        self.assertEqual(len(posts), 1)
        self.assertIn("Eitr after interrupted package upgrade", posts[0])
        self.assertLess(calls.index(posts[0]), next(i for i, c in enumerate(calls) if "pre" in c))
        pending = (self.state / "pending-upgrade.json").read_text()
        self.assertIn('"snapshot": "4"', pending)
        self.assertFalse(any(self.state.glob("boot-backups/*")), "no archive when /boot is in the root snapshot")

    def test_failed_boot_archive_creates_no_snapshot(self):
        with patch.object(system, "snapshot_supported"), \
                patch.object(system, "separate_boot_mounts", return_value=["/boot"]), \
                patch.object(system, "run", side_effect=lambda args, **_: (_ for _ in ()).throw(
                    system.subprocess.CalledProcessError(2, args)) if args[0] == "tar" else None), \
                patch.object(system, "output") as output:
            with self.assertRaises(system.subprocess.CalledProcessError):
                system.snapshot_pre()
        output.assert_not_called()
        self.assertFalse((self.state / "pending-upgrade.json").exists())
        self.assertEqual(list((self.state / "boot-backups").iterdir()), [])

    def test_separate_boot_is_archived_under_snapshot_number_and_pruned(self):
        archives = self.state / "boot-backups"
        for number in range(1, 12):
            (archives / str(number)).mkdir(parents=True)

        def run(args, **_):
            if args[0] == "tar":
                Path(args[4]).write_bytes(b"tar")

        with patch.object(system, "snapshot_supported"), \
                patch.object(system, "separate_boot_mounts", return_value=["/boot"]), \
                patch.object(system, "run", side_effect=run), \
                patch.object(system, "output", return_value="12"), patch("builtins.print"):
            system.snapshot_pre()
        self.assertTrue((archives / "12/boot.tar").is_file())
        remaining = sorted(int(path.name) for path in archives.iterdir())
        self.assertEqual(remaining, list(range(3, 13)))


class AuthenticationPolicyTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.pam = self.root / "pam.d"
        self.pam.mkdir()
        for service in system.SERVICES:
            (self.pam / service).write_text(f"auth include {service}-original\n")
        for target, value in (("STATE", self.root / "state"), ("PAM", self.pam),
                              ("U2F_KEYS", self.root / "security/eitr/u2f_keys")):
            patcher = patch.object(system, target, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def test_u2f_authfile_is_readable_by_lockscreen_user(self):
        system.write_u2f_keys("alice", "alice:handle,key\n")
        self.assertEqual(system.U2F_KEYS.stat().st_mode & 0o777, 0o644)
        self.assertEqual(system.U2F_KEYS.parent.stat().st_mode & 0o777, 0o755)
        system.write_u2f_keys("bob", "bob:other\n")
        system.write_u2f_keys("alice", "alice:replaced\n")
        self.assertEqual(system.U2F_KEYS.read_text(), "bob:other\nalice:replaced\n")

    def test_fingerprint_follows_the_selected_method_everywhere(self):
        # The lockscreen must honor "password only", so fingerprint stays in
        # PAM rather than hyprlock's always-on native fingerprint option.
        backup, enabled = system.write_pam("fingerprint")
        self.assertEqual(enabled, system.SERVICES)
        for service in system.SERVICES:
            self.assertIn("pam_fprintd", (self.pam / service).read_text())
        hyprlock_conf = (ROOT.parent / "hypr/hyprlock.conf").read_text()
        self.assertNotRegex(hyprlock_conf, r"fingerprint \{\s*enabled = true")

    def test_failed_pam_write_restores_every_file(self):
        original = {service: (self.pam / service).read_text() for service in system.SERVICES}
        real_atomic = system.atomic
        writes = []

        def flaky(path, content, **kwargs):
            writes.append(path.name)
            if len(writes) == 2:
                raise OSError("disk full")
            real_atomic(path, content, **kwargs)

        with patch.object(system, "atomic", side_effect=flaky):
            with self.assertRaises(OSError):
                system.write_pam("fido2")
        self.assertEqual({service: (self.pam / service).read_text() for service in system.SERVICES}, original)

    def test_auth_restore_uses_named_backup_only(self):
        original = {service: (self.pam / service).read_text() for service in system.SERVICES}
        backup, _ = system.write_pam("fido2")
        self.assertIn("pam_u2f", (self.pam / "sudo").read_text())
        with patch("builtins.print"):
            system.restore_auth(backup.name)
        self.assertEqual({service: (self.pam / service).read_text() for service in system.SERVICES}, original)
        for name in ("../pam.d", "missing", "/etc"):
            with self.assertRaises(RuntimeError):
                system.restore_auth(name)

    def test_enable_auth_refuses_root_or_missing_sudo_user(self):
        for user in ("", "root"):
            with patch.dict(system.os.environ, {"SUDO_USER": user}), patch.object(system, "write_pam") as write:
                with self.assertRaises(RuntimeError):
                    system.enable_auth("fido2")
                write.assert_not_called()

    def test_fido2_registration_must_be_owned_regular_file(self):
        home = self.root / "home"
        registration = home / ".config/Yubico/u2f_keys"
        registration.parent.mkdir(parents=True)
        elsewhere = self.root / "elsewhere"
        elsewhere.write_text("alice:handle\n")
        registration.symlink_to(elsewhere)
        with self.assertRaises(OSError):
            system.read_user_u2f_keys("alice", Account(home, system.os.getuid()))
        registration.unlink()
        registration.write_text("alice:handle\n")
        with self.assertRaisesRegex(RuntimeError, "owned by the desktop user"):
            system.read_user_u2f_keys("alice", Account(home, system.os.getuid() + 1))
        self.assertEqual(system.read_user_u2f_keys("alice", Account(home, system.os.getuid())), "alice:handle\n")
        registration.write_text("mallory:handle\n")
        with self.assertRaisesRegex(RuntimeError, "Invalid"):
            system.read_user_u2f_keys("alice", Account(home, system.os.getuid()))
