import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "display_primary", Path(__file__).parents[1] / "scripts/display-primary.py"
)
display_primary = importlib.util.module_from_spec(spec)
spec.loader.exec_module(display_primary)


class DisplayPrimaryTests(unittest.TestCase):
    def setUp(self):
        self.monitors = [
            {"name": "DP-3", "width": 2560, "height": 1080, "refreshRate": 144},
            {"name": "HDMI-A-1", "width": 1920, "height": 1080, "refreshRate": 144},
        ]

    def test_saved_choice_wins(self):
        self.assertEqual(
            display_primary.choose_primary(self.monitors, "HDMI-A-1", True),
            "HDMI-A-1",
        )

    def test_missing_saved_screen_falls_back(self):
        self.assertEqual(
            display_primary.choose_primary(self.monitors[:1], "HDMI-A-1"), "DP-3"
        )

    def test_portable_default_uses_largest(self):
        self.assertEqual(
            display_primary.choose_primary(self.monitors, portable=True), "DP-3"
        )

    def test_existing_default_keeps_hdmi_preference(self):
        self.assertEqual(display_primary.choose_primary(self.monitors), "HDMI-A-1")

    def test_portable_tie_keeps_compositor_order(self):
        monitors = [
            {"name": "eDP-1", "width": 1920, "height": 1080, "refreshRate": 60},
            {"name": "DP-1", "width": 1920, "height": 1080, "refreshRate": 165},
        ]
        self.assertEqual(display_primary.choose_primary(monitors, portable=True), "eDP-1")

    def test_shell_fallback_mirrors_python_preference(self):
        shell = (Path(__file__).parents[1] / "shell.qml").read_text()
        start = shell.index("function targetScreens()")
        body = shell[start:shell.index("Variants {", start)]
        first, second = display_primary.LEGACY_PREFERENCE
        self.assertLess(body.index('"' + first + '"'), body.index('"' + second + '"'))
        self.assertIn("portableDisplayMode && largest", body)
        self.assertIn("width * screens[i].height > largest.width * largest.height", body)

    def test_set_persists_only_connected_display(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(display_primary, "CONFIG_DIR", Path(directory)), \
                patch.object(display_primary, "PREFERENCE", Path(directory) / "primary-display"), \
                patch.object(display_primary, "active_monitors", return_value=self.monitors):
            with self.assertRaisesRegex(ValueError, "not connected"):
                display_primary.set_primary("DP-9")
            self.assertFalse(display_primary.PREFERENCE.exists())
            result = display_primary.set_primary("DP-3")
            self.assertEqual(result["primary"], "DP-3")
            self.assertEqual(display_primary.PREFERENCE.read_text(), "DP-3\n")


if __name__ == "__main__":
    unittest.main()
