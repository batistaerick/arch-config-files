import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("software", ROOT / "walker/scripts/actions/install/software.py")
software = importlib.util.module_from_spec(spec)
spec.loader.exec_module(software)


class SoftwareTests(unittest.TestCase):
    def test_geforce_adds_runtime_remote_before_install(self):
        data = json.loads((ROOT / "distro/software.json").read_text())
        with patch.object(software, "catalog", return_value=data), patch.object(software, "run") as run:
            software.recipe("gaming", "geforcenow")
            calls = [call.args[0] for call in run.call_args_list]
            self.assertEqual(calls[0], ["flatpak", "remote-add", "--user", "--if-not-exists",
                                      "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"])
            self.assertEqual(calls[-1], ["flatpak", "install", "--user", "GeForceNOW", "com.nvidia.geforcenow"])

    def test_package_picker_installs_all_selected_packages(self):
        with patch.object(software, "text", return_value="firefox\nchromium"), \
                patch.object(software.subprocess, "run", return_value=SimpleNamespace(returncode=0, stdout="firefox\nchromium\n")) as picker, \
                patch.object(software, "install") as install:
            software.package_picker("pacman")
            self.assertIn("--multi", picker.call_args.args[0])
            install.assert_called_once_with("pacman", ["firefox", "chromium"])

    def test_package_picker_cancel_never_installs(self):
        with patch.object(software, "text", return_value="firefox"), \
                patch.object(software.subprocess, "run", return_value=SimpleNamespace(returncode=130, stdout="")), \
                patch.object(software, "install") as install:
            software.package_picker("pacman")
            install.assert_not_called()

    def test_gaming_installed_steam_launches_without_installing(self):
        with patch.object(software.shutil, "which", return_value="/usr/bin/steam"), \
                patch.object(software.subprocess, "Popen") as launch, patch.object(software, "terminal") as terminal:
            software.gaming("steam")
            launch.assert_called_once_with(["steam"], start_new_session=True)
            terminal.assert_not_called()

    def test_gaming_missing_apps_open_install_terminal(self):
        for identifier in ("steam", "geforcenow"):
            with self.subTest(identifier=identifier), patch.object(software.shutil, "which", return_value=None), \
                    patch.object(software.subprocess, "Popen") as launch, patch.object(software, "terminal") as terminal:
                software.gaming(identifier)
                terminal.assert_called_once_with("python3", str(software.SCRIPT), "gaming-install", identifier)
                launch.assert_not_called()

    def test_gaming_flatpak_checks_app_not_just_flatpak_binary(self):
        for installed in (True, False):
            with self.subTest(installed=installed), patch.object(software.shutil, "which", return_value="/usr/bin/flatpak"), \
                    patch.object(software.subprocess, "run", return_value=SimpleNamespace(returncode=0 if installed else 1)), \
                    patch.object(software.subprocess, "Popen") as launch, patch.object(software, "terminal") as terminal:
                software.gaming("geforcenow")
                if installed:
                    launch.assert_called_once_with(["flatpak", "run", "com.nvidia.geforcenow"], start_new_session=True)
                    terminal.assert_not_called()
                else:
                    launch.assert_not_called()
                    terminal.assert_called_once()

    def test_gaming_installer_bootstraps_missing_flatpak(self):
        with patch.object(software.shutil, "which", return_value=None), \
                patch.object(software, "install") as install, patch.object(software, "recipe") as recipe:
            software.gaming_install("geforcenow")
            install.assert_called_once_with("pacman", ["flatpak"])
            recipe.assert_called_once_with("gaming", "geforcenow")

    def test_install_keeps_arguments_separate_and_deduplicates(self):
        with patch.object(software, "run") as run:
            software.install("pacman", ["firefox", "firefox"])
            run.assert_called_once_with(["sudo", "pacman", "-Syu", "--needed", "--", "firefox"])

    def test_invalid_package_never_executes(self):
        for name in ("--overwrite", "firefox; reboot", "$(id)", "../x", ""):
            with self.subTest(name=name), patch.object(software, "run") as run:
                with self.assertRaises(ValueError):
                    software.install("pacman", [name])
                run.assert_not_called()

    def test_aur_keeps_review_prompts_and_runs_as_user(self):
        with patch.object(software.os, "geteuid", return_value=1000), patch.object(software, "run") as run:
            software.install("aur", ["google-chrome"])
            run.assert_called_once_with(["yay", "-S", "--needed", "--", "google-chrome"])
        with patch.object(software.os, "geteuid", return_value=0), patch.object(software, "run") as run:
            with self.assertRaises(RuntimeError): software.install("aur", ["google-chrome"])
            run.assert_not_called()

    def test_uninstall_cancel_never_opens_terminal(self):
        with patch.object(software, "resolve_app", return_value=("pacman", "firefox")), \
                patch.object(software, "confirm", return_value=False), patch.object(software, "terminal") as terminal:
            software.uninstall("ignored.desktop")
            terminal.assert_not_called()

    def test_remove_does_not_force_or_recursively_delete_dependencies(self):
        with patch.object(software, "run") as run:
            software.remove("pacman", "firefox")
            run.assert_called_once_with(["sudo", "pacman", "-R", "--", "firefox"])

    def test_search_is_read_only_and_empty_query_has_no_network(self):
        with patch.object(software.subprocess, "run") as run:
            self.assertEqual(software.search("aur", "")[0]["name"], "")
            run.assert_not_called()
            run.return_value = SimpleNamespace(returncode=0, stdout="extra/firefox 1.0\n    Web browser\n", stderr="")
            self.assertEqual(software.search("pacman", "firefox")[0]["name"], "firefox")
            self.assertIn("-Ss", run.call_args.args[0])

    def test_catalog_names_and_no_default_grok(self):
        data = json.loads((ROOT / "distro/software.json").read_text())
        for entries in data.values():
            for item in entries.values():
                for package in item["packages"]: software.package_name(package)
        self.assertEqual(data["languages"]["java"]["manager"], "SDKMAN")
        self.assertEqual(data["languages"]["node"]["manager"], "NVM")
        self.assertEqual(data["browsers"]["tor"]["source"], "pacman")
        self.assertEqual(data["tools"]["lazydocker"]["source"], "pacman")

    def test_walker_delete_and_tab_actions_are_scoped(self):
        config = (ROOT / "walker/config.toml").read_text()
        self.assertIn('default = [ "desktopapplications", "websearch" ]', config)
        search = (ROOT / "walker/scripts/menus/search.sh").read_text()
        self.assertIn("--provider desktopapplications", search)
        self.assertIn('{ action = "open", label = "Open", bind = "Return", default = true', config)
        self.assertIn('action = "app_uninstall", label = "Uninstall", bind = "Delete"', config)
        self.assertIn('action = "package_toggle", label = "Select", bind = "Tab"', config)
        self.assertIn('action = "package_review", label = "Review build", bind = "ctrl b"', config)

    def test_existing_desktop_update_does_not_require_distro_snapshot_setup(self):
        script = (ROOT / "walker/scripts/actions/system/update.sh").read_text()
        self.assertNotIn("exit 1", script)
        self.assertIn("sudo pacman -Syu", script)
        hook = (ROOT / "distro/hooks/05-eitr-snapshot-pre.hook").read_text()
        self.assertIn("AbortOnFail", hook)
