import os
from pathlib import Path
import re
import sys
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
THEMES = ROOT / "themes"
sys.path.insert(0, str(ROOT / "walker/scripts/themes"))
import palette  # noqa: E402

REQUIRED = {"backgrounds", "btop.theme", "colors.toml", "display-name", "dolphin.theme",
            "icons.theme", "neovim.lua", "preview.png", "rgb.color", "vscode.json"}
OPTIONAL = {"artwork.md", "light.mode", "references", "vscode.vsix"}
COLOR_KEYS = {"accent", "background", "foreground", "cursor", "selection_background",
              "selection_foreground", *(f"color{index}" for index in range(16))}
# Base themes shipped by kvantum-theme-catppuccin-git.
KVANTUM_THEME = re.compile(r"^catppuccin-(latte|frappe|macchiato|mocha)-(rosewater|flamingo|pink|mauve|red|"
                           r"maroon|peach|yellow|green|teal|sky|sapphire|blue|lavender)$")


def theme_dirs():
    return sorted(path for path in THEMES.iterdir() if path.is_dir())


class ThemeSchemaTests(unittest.TestCase):
    def test_every_theme_has_required_and_only_known_files(self):
        self.assertTrue(theme_dirs())
        for theme in theme_dirs():
            with self.subTest(theme=theme.name):
                names = {path.name for path in theme.iterdir() if path.name != ".DS_Store"}
                self.assertEqual(REQUIRED - names, set())
                self.assertEqual(names - REQUIRED - OPTIONAL, set())
                self.assertTrue(any((theme / "backgrounds").iterdir()))
                self.assertTrue((theme / "display-name").read_text().strip())

    def test_palettes_are_complete_and_light_mode_matches_luminance(self):
        for theme in theme_dirs():
            with self.subTest(theme=theme.name):
                colors = palette.load(theme)
                self.assertEqual(COLOR_KEYS - set(colors), set())
                light_palette = palette.luminance(colors["background"]) > palette.luminance(colors["foreground"])
                self.assertEqual(palette.is_light(theme), light_palette)

    def test_dolphin_theme_resolves_to_matching_kvantum_flavor(self):
        for theme in theme_dirs():
            with self.subTest(theme=theme.name):
                name = (theme / "dolphin.theme").read_text().strip()
                match = KVANTUM_THEME.match(name)
                self.assertTrue(match or (ROOT / "Kvantum" / f"{name}#").is_dir(), name)
                if match:
                    self.assertEqual(match.group(1) == "latte", palette.is_light(theme), name)

    def test_elephant_actions_reference_existing_scripts(self):
        for menu in sorted((ROOT / "elephant/menus").glob("*.toml")):
            data = tomllib.loads(menu.read_text())
            for entry in data.get("entries", []):
                for command in (entry.get("actions") or {}).values():
                    for match in re.finditer(r"(\S*)\s*\$HOME/\.config/(\S+)", command):
                        interpreter, relative = match.groups()
                        script = ROOT / relative
                        with self.subTest(menu=menu.name, script=relative):
                            self.assertTrue(script.is_file())
                            if Path(interpreter).name not in {"bash", "python3", "sh"}:
                                self.assertTrue(os.access(script, os.X_OK))

    def test_elephant_lua_modules_reference_existing_repo_files(self):
        for source in [*ROOT.joinpath("elephant").rglob("*.lua"), *ROOT.joinpath("walker/scripts/menus").glob("*.lua")]:
            for relative in re.findall(r'"/\.config/((?:elephant|walker)/[^"]+\.(?:lua|sh|py))"', source.read_text()):
                with self.subTest(source=source.name, path=relative):
                    self.assertTrue((ROOT / relative).is_file())


if __name__ == "__main__":
    unittest.main()
