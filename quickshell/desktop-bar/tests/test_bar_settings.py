import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "bar_settings", Path(__file__).parents[1] / "scripts/bar-settings.py"
)
bar_settings = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bar_settings)


class BarSettingsTests(unittest.TestCase):
    def test_no_background_persists(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(bar_settings, "SETTINGS", Path(directory) / "bar.json"):
            bar_settings.save_settings({"appearance": "none"})
            self.assertEqual(bar_settings.read_settings()["appearance"], "none")

    def test_defaults_and_persistence(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(bar_settings, "SETTINGS", Path(directory) / "bar.json"):
            self.assertEqual(bar_settings.read_settings(), bar_settings.DEFAULTS)
            bar_settings.save_settings({"appearance": "solid", "edge": "left"})
            self.assertEqual(bar_settings.read_settings(), {
                "appearance": "solid", "layout": "unified", "edge": "left"
            })
            bar_settings.save_settings({"layout": "split"})
            self.assertEqual(bar_settings.read_settings()["appearance"], "solid")

    def test_invalid_value_does_not_replace_file(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(bar_settings, "SETTINGS", Path(directory) / "bar.json"):
            bar_settings.save_settings({"edge": "bottom"})
            with self.assertRaises(ValueError):
                bar_settings.save_settings({"edge": "somewhere"})
            self.assertEqual(bar_settings.read_settings()["edge"], "bottom")

    def test_bad_file_falls_back_to_defaults(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(bar_settings, "SETTINGS", Path(directory) / "bar.json"):
            bar_settings.SETTINGS.write_text("not json")
            self.assertEqual(bar_settings.read_settings(), bar_settings.DEFAULTS)


if __name__ == "__main__":
    unittest.main()
