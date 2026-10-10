import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


# flock is Linux-only; a shell function stands in for it on other hosts.
FLOCK_MOCK = "flock() { return 0; }\n"


def run_protected_update(mocks):
    source = (ROOT / "walker/scripts/actions/system/update.sh").read_text()
    with tempfile.TemporaryDirectory() as directory:
        policy = Path(directory) / "policy"
        policy.touch()
        source = source.replace("/etc/eitr/system-update-policy.conf", str(policy))
        source = source.replace("/usr/local/lib/eitr/eitr-system", "/usr/bin/true")
        environment = dict(os.environ, XDG_RUNTIME_DIR=directory)
        return subprocess.run(["bash", "-c", FLOCK_MOCK + mocks + source, "update", "system"],
                              capture_output=True, text=True, env=environment)


class UpdateWorkflowTests(unittest.TestCase):
    def test_failed_snapshot_prevents_package_updates(self):
        result = run_protected_update("""
sudo() { echo "sudo $*"; if [[ "$*" == *snapshot-pre* ]]; then return 1; fi; }
yay() { echo "yay $*"; }
""")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("snapshot-pre", result.stdout)
        self.assertNotIn("pacman", result.stdout)
        self.assertNotIn("yay", result.stdout)
        self.assertNotIn("snapshot-post", result.stdout)

    def test_failed_upgrade_still_records_post_snapshot(self):
        result = run_protected_update("""
sudo() { echo "sudo $*"; if [[ "$*" == *pacman* ]]; then return 1; fi; }
yay() { echo "yay $*"; }
""")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("snapshot-post failed", result.stdout)
        self.assertNotIn("yay", result.stdout)

    def test_successful_upgrade_records_success(self):
        result = run_protected_update("""
sudo() { echo "sudo $*"; }
yay() { echo "yay $*"; }
""")
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = result.stdout.splitlines()
        self.assertEqual(lines[0].split()[-1], "snapshot-pre")
        self.assertEqual(lines[-1].split()[-2:], ["snapshot-post", "success"])

    def test_advanced_aur_updates_only_aur_without_snapshots(self):
        source = (ROOT / "walker/scripts/actions/system/update.sh").read_text()
        mocks = 'sudo() { echo "sudo $*"; }; yay() { echo "yay $*"; }; export -f sudo yay\n'
        result = subprocess.run(["bash", "-c", mocks + source, "update", "yay"],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), "yay -Sua --devel")
