from pathlib import Path
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
MENUS = ROOT / "elephant/menus"


def menu(name):
    return tomllib.loads((MENUS / (name + ".toml")).read_text())


class MenuStructureTests(unittest.TestCase):
    def test_security_groups_authentication_methods(self):
        entries = menu("security")["entries"]
        for name in ("fingerprint", "fido2"):
            entry = next(entry for entry in entries if entry.get("submenu") == name)
            self.assertEqual(entry.get("subtext"), ">")
            self.assertEqual(menu(name)["parent"], "security")
        self.assertFalse(any("FIDO2" in entry["text"] and "actions" in entry for entry in entries))
        layout = ROOT / "walker/themes/current"
        self.assertEqual((layout / "item_menus-security.xml").read_text(),
                         (layout / "item_menus-system.xml").read_text())
    def test_package_entries_open_terminal_pickers(self):
        for entry in menu("install")["entries"][:2]:
            self.assertNotIn("submenu", entry)
            self.assertIn("picker-launch", entry["actions"]["open"])
    def test_ai_install_is_only_under_install(self):
        self.assertNotIn("ai-install", [entry.get("submenu") for entry in menu("ai-tools")["entries"]])
        self.assertIn("ai-install", [entry.get("submenu") for entry in menu("install")["entries"]])

    def test_gaming_has_only_app_entries(self):
        self.assertEqual([entry["text"] for entry in menu("gaming")["entries"]], ["Steam", "GeForce NOW"])
    def test_install_and_gaming_follow_learn(self):
        names = [entry["text"] for entry in menu("main")["entries"]]
        start = names.index("Learn")
        self.assertEqual(names[start:start + 3], ["Learn", "Install", "Gaming"])

    def test_optional_runtimes_belong_to_install(self):
        development = [entry.get("submenu") for entry in menu("development")["entries"]]
        install = [entry.get("submenu") for entry in menu("install")["entries"]]
        for name in ("languages", "javascript-tools"):
            self.assertNotIn(name, development)
            self.assertIn(name, install)
            self.assertIn('Parent = "install"', (MENUS / (name + ".lua")).read_text())
        self.assertNotIn("developer-tools", development)
        self.assertFalse((MENUS / "developer-tools.lua").exists())
        packages = (ROOT / "distro/packages.txt").read_text().splitlines()
        for name in ("lazygit", "lazydocker"):
            self.assertIn(name, packages)

    def test_fingerprint_has_its_own_submenu(self):
        entries = menu("security")["entries"]
        self.assertTrue(any(entry.get("submenu") == "fingerprint" for entry in entries))
        self.assertFalse(any("Fingerprint" in entry["text"] and "actions" in entry for entry in entries))
        self.assertEqual(menu("fingerprint")["parent"], "security")
        self.assertEqual(len(menu("fingerprint")["entries"]), 2)
