from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class UpdateWorkflowTests(unittest.TestCase):
    def test_failed_snapshot_prevents_package_updates(self):
        source = (ROOT / "walker/scripts/actions/system/update.sh").read_text()
        with tempfile.TemporaryDirectory() as directory:
            policy = Path(directory) / "policy"
            policy.touch()
            source = source.replace("/etc/eitr/system-update-policy.conf", str(policy))
            source = source.replace("/usr/local/lib/eitr/eitr-system", "/usr/bin/true")
            mocks = """
sudo() { echo "sudo $*"; if [[ "$*" == *snapshot-pre* ]]; then return 1; fi; }
yay() { echo "yay $*"; }
export -f sudo yay
"""
            result = subprocess.run(["bash", "-c", mocks + source, "update", "system"],
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("snapshot-pre", result.stdout)
            self.assertNotIn("pacman", result.stdout)
            self.assertNotIn("yay", result.stdout)

    def test_advanced_aur_updates_only_aur_without_snapshots(self):
        source = (ROOT / "walker/scripts/actions/system/update.sh").read_text()
        mocks = 'sudo() { echo "sudo $*"; }; yay() { echo "yay $*"; }; export -f sudo yay\n'
        result = subprocess.run(["bash", "-c", mocks + source, "update", "yay"],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), "yay -Sua --devel")
