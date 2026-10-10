from pathlib import Path
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
MENUS = ROOT / "elephant/menus"


def menu(name):
    return tomllib.loads((MENUS / (name + ".toml")).read_text())


class MenuStructureTests(unittest.TestCase):
    def test_submenus_are_alphabetical(self):
        for path in MENUS.glob("*.toml"):
            if path.stem == "main":
                continue
            names = [entry["text"] for entry in tomllib.loads(path.read_text()).get("entries", [])]
            self.assertEqual(names, sorted(names, key=str.lower), path.name)
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
    def test_install_submenus_show_parent_marker(self):
        for entry in menu("install")["entries"]:
            if "submenu" in entry:
                self.assertEqual(entry.get("subtext"), ">", entry["text"])
        layout = ROOT / "walker/themes/current"
        self.assertEqual((layout / "item_menus-install.xml").read_text(),
                         (layout / "item_menus-system.xml").read_text())

    def test_removed_package_menus_stay_removed(self):
        self.assertFalse((MENUS / "packages-pacman.lua").exists())
        self.assertFalse((MENUS / "packages-aur.lua").exists())
        self.assertFalse((ROOT / "walker/scripts/menus/package-menu.lua").exists())

    def test_package_entries_open_terminal_pickers(self):
        for entry in [entry for entry in menu("install")["entries"] if entry["text"] in ("Pacman", "Yay (AUR)")]:
            self.assertNotIn("submenu", entry)
            self.assertIn("picker-launch", entry["actions"]["open"])
    def test_ai_install_is_only_under_install(self):
        self.assertNotIn("ai-install", [entry.get("submenu") for entry in menu("ai-tools")["entries"]])
        self.assertIn("ai-install", [entry.get("submenu") for entry in menu("install")["entries"]])

    def test_gaming_has_only_app_entries(self):
        self.assertEqual([entry["text"] for entry in menu("gaming")["entries"]], ["GeForce NOW", "Steam"])
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

    def test_tpm_unlock_has_its_own_security_submenu(self):
        entry = next(entry for entry in menu("security")["entries"] if entry.get("submenu") == "tpm-unlock")
        self.assertEqual(entry.get("subtext"), ">")
        self.assertEqual(menu("tpm-unlock")["parent"], "security")
        for item in menu("tpm-unlock")["entries"]:
            self.assertIn("security.py tpm-", item["actions"]["open"])

    def test_battery_limit_lives_under_system(self):
        entry = next(entry for entry in menu("system")["entries"] if entry.get("submenu") == "battery-limit")
        self.assertEqual(entry.get("subtext"), ">")
        self.assertEqual(menu("battery-limit")["parent"], "system")

    def test_secure_boot_guide_is_documentation_only(self):
        entry = next(entry for entry in menu("security")["entries"] if entry["text"] == "Secure Boot Guide")
        action = entry["actions"]["open"]
        self.assertIn("/usr/share/eitr/SECURE-BOOT.md", action)
        self.assertNotIn("sbctl", action)
        self.assertNotIn("sudo", action)
        self.assertIn("distro/SECURE-BOOT.md", (ROOT / "distro/pkg/eitr-desktop/PKGBUILD").read_text())
        self.assertTrue((ROOT / "distro/SECURE-BOOT.md").is_file())
