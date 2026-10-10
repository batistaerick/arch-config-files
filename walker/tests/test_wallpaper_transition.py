import importlib.util
from pathlib import Path
import tempfile
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

    def test_backing_wallpaper_changes_before_reveal(self):
        qml = (ROOT / "quickshell/wallpaper-transition/shell.qml").read_text()
        self.assertIn("commit.running = true", qml.split("NumberAnimation")[0])
        self.assertIn("if (exitCode === 0) reveal.start()", qml)
        self.assertIn("onFinished: handoff.start()", qml)
        self.assertIn("onTriggered: Qt.exit(1)", qml)

    def test_transition_does_not_capture_input(self):
        qml = (ROOT / "quickshell/wallpaper-transition/shell.qml").read_text()
        self.assertIn("WlrLayer.Bottom", qml)
        self.assertIn("mask: Region {}", qml)
        self.assertIn("duration: 650", qml)
        self.assertIn("anchors.horizontalCenter", qml)

    def test_failure_still_commits_static_wallpaper(self):
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "wallpaper.png"
            image.write_bytes(b"mock")
            with patch.object(transition, "runtime", return_value=Path(directory)), \
                    patch.object(transition, "snapshot", return_value=""), \
                    patch.object(transition.subprocess, "run", side_effect=OSError("missing quickshell")), \
                    patch.object(transition, "commit") as commit:
                transition.apply(str(image))
                commit.assert_called_once_with(str(image))

    def test_every_existing_wallpaper_entrypoint_uses_shared_helper(self):
        for filename in ("walker/scripts/actions/wallpaper/apply.sh", "walker/scripts/actions/style/apply.sh"):
            self.assertIn("transition.py", (ROOT / filename).read_text())
        for filename in ("walker/scripts/actions/wallpaper/next.sh", "walker/scripts/menus/style/wallpaper.sh"):
            self.assertIn("/wallpaper/apply.sh", (ROOT / filename).read_text())
