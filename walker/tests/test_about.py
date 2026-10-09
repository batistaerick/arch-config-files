import importlib.util
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("eitr_about", ROOT / "fastfetch/eitr.py")
ABOUT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ABOUT)


class AboutTests(unittest.TestCase):
    def test_missing_theme_has_safe_defaults(self):
        with tempfile.TemporaryDirectory() as directory:
            config = ABOUT.build_config(Path(directory), Path(directory), False)
        self.assertEqual(config["logo"]["type"], "none")
        self.assertIn({"type": "custom", "key": "Theme", "format": "Default"}, config["modules"])

    def test_theme_is_read_again_and_nested_palette_supported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            theme = root / "theme/current"
            theme.mkdir(parents=True)
            (theme / "display-name").write_text("Test Light\n")
            palette = theme / "colors.toml"
            palette.write_text('[colors]\naccent = "#112233"\ncolor0 = "#abcdef"\n')
            first = ABOUT.build_config(root, root, False)
            self.assertEqual(first["display"]["color"]["keys"], "#112233")
            self.assertIn("{##abcdef}", first["modules"][-2]["format"])
            palette.write_text('accent = "#445566"\n')
            self.assertEqual(ABOUT.build_config(root, root, False)["display"]["color"]["keys"], "#445566")

    def test_invalid_color_cannot_inject_terminal_commands(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            theme = root / "theme/current"
            theme.mkdir(parents=True)
            (theme / "colors.toml").write_text('accent = "invalid"\n')
            self.assertEqual(ABOUT.build_config(root, root, False)["display"]["color"]["keys"], "#509475")

    def test_selected_logo_renders_seventeen_rows(self):
        logo = ABOUT.terminal_logo(ROOT / "fastfetch/assets/eitr.png")
        self.assertEqual(len(logo.splitlines()), 17)
        self.assertIn("▀", logo)


if __name__ == "__main__":
    unittest.main()
