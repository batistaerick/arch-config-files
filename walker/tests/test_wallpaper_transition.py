import importlib.util
from pathlib import Path
import tempfile
import subprocess
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("transition", ROOT / "walker/scripts/actions/wallpaper/transition.py")
transition = importlib.util.module_from_spec(spec)
spec.loader.exec_module(transition)


class WallpaperTests(unittest.TestCase):
    def test_success_does_not_reapply_after_transition(self):
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "wallpaper.png"
            image.write_bytes(b"mock")
            with patch.object(transition, "runtime", return_value=Path(directory)), \
                    patch.object(transition, "snapshot", return_value=""), \
                    patch.object(transition.subprocess, "run"), patch.object(transition, "commit") as commit:
                transition.apply(str(image))
                commit.assert_not_called()

    def test_backing_wallpaper_changes_only_under_completed_reveal(self):
        qml = (ROOT / "quickshell/wallpaper-transition/shell.qml").read_text()
        self.assertNotIn("commit.running = true", qml.split("NumberAnimation")[0])
        self.assertIn("if (exitCode === 0) handoff.start()", qml)
        self.assertIn("onFinished: commit.running = true", qml)
        self.assertIn("prepare.start()", qml)
        self.assertIn("onTriggered: Qt.exit(1)", qml)

    def test_transition_does_not_capture_input(self):
        qml = (ROOT / "quickshell/wallpaper-transition/shell.qml").read_text()
        self.assertIn("WlrLayer.Bottom", qml)
        self.assertIn("mask: Region {}", qml)
        self.assertIn("duration: 650", qml)
        self.assertIn("anchors.centerIn", qml)
        self.assertIn("maskSource: circleMask", qml)
        self.assertIn("Math.sqrt(window.width * window.width + window.height * window.height)", qml)

    def test_failure_still_commits_static_wallpaper(self):
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "wallpaper.png"
            image.write_bytes(b"mock")
            with patch.object(transition, "runtime", return_value=Path(directory)), \
                    patch.object(transition, "snapshot", return_value=""), \
                    patch.object(transition.subprocess, "run", side_effect=OSError("missing quickshell")), \
                    patch.object(transition, "commit") as commit:
                transition.apply(str(image))
                commit.assert_called_once_with(str(image.resolve()))

    def test_one_failing_monitor_still_persists_wallpaper(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            image = home / "wallpaper.png"
            image.write_bytes(b"mock")
            monitors = '[{"name": "DP-1"}, {"name": "HDMI-A-1"}]'
            calls = []

            def run(command, check):
                calls.append(command[-1])
                if command[-1].startswith("DP-1,"):
                    raise subprocess.CalledProcessError(1, command)

            with patch.object(transition.Path, "home", return_value=home), \
                    patch.object(transition.subprocess, "check_output", return_value=monitors), \
                    patch.object(transition.subprocess, "run", side_effect=run):
                with self.assertRaisesRegex(transition.CommitError, "DP-1"):
                    transition.commit(str(image))
            self.assertEqual(len(calls), 2, "every monitor is attempted")
            self.assertEqual((home / ".cache/current-wallpaper-image").resolve(), image.resolve())
            self.assertEqual((home / ".cache/current-wallpaper").read_text().strip(), str(image.resolve()))

    def test_apply_fallback_commit_failure_is_not_fatal(self):
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "wallpaper.png"
            image.write_bytes(b"mock")
            with patch.object(transition, "runtime", return_value=Path(directory)), \
                    patch.object(transition, "snapshot", return_value=""), \
                    patch.object(transition.subprocess, "run", side_effect=OSError("missing quickshell")), \
                    patch.object(transition, "commit", side_effect=transition.CommitError("hyprpaper failed on: DP-1")), \
                    patch("sys.stderr"):
                transition.apply(str(image))

    def test_image_errors_fail_immediately(self):
        qml = (ROOT / "quickshell/wallpaper-transition/shell.qml").read_text()
        self.assertIn("status === Image.Error", qml)
        self.assertEqual(qml.count("onStatusChanged: root.failOnError(status)"), 2)

    def test_wallpapers_are_listed_in_natural_order(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("10.png", "2.JPG", "1.webp", "notes.txt"):
                (root / name).write_bytes(b"mock")
            names = [path.name for path in transition.wallpapers(root)]
            self.assertEqual(names, ["1.webp", "2.JPG", "10.png"])
            self.assertEqual(transition.wallpapers(root / "missing"), [])

    def test_every_existing_wallpaper_entrypoint_uses_shared_helper(self):
        for filename in ("walker/scripts/actions/wallpaper/apply.sh", "walker/scripts/actions/style/apply.sh"):
            self.assertIn("transition.py", (ROOT / filename).read_text())
        for filename in ("walker/scripts/actions/wallpaper/next.sh",):
            self.assertIn("/wallpaper/apply.sh", (ROOT / filename).read_text())
