import importlib.util
import io
import json
import os
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
import re
import tempfile
import tomllib
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
spec = importlib.util.spec_from_file_location("welcome_state", ROOT / "scripts/welcome-state.py")
welcome_state = importlib.util.module_from_spec(spec)
spec.loader.exec_module(welcome_state)


def run(*args):
    output = io.StringIO()
    with redirect_stdout(output), redirect_stderr(io.StringIO()):
        code = welcome_state.main(list(args))
    return code, json.loads(output.getvalue()) if code == 0 else None


class WelcomeStateTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        patcher = patch.dict(os.environ, {"XDG_STATE_HOME": self.directory.name})
        patcher.start()
        self.addCleanup(patcher.stop)
        self.state = Path(self.directory.name) / "eitr"

    def mark_installed(self):
        self.state.mkdir(parents=True, exist_ok=True)
        (self.state / "installed-paths").write_text(".config/quickshell\n")

    def test_state_lives_under_xdg_state_home(self):
        self.assertEqual(welcome_state.state_dir(), self.state)
        with patch.dict(os.environ, {"XDG_STATE_HOME": ""}), patch.object(Path, "home", return_value=Path("/h")):
            self.assertEqual(welcome_state.state_dir(), Path("/h/.local/state/eitr"))

    def test_existing_desktop_without_installer_record_is_not_interrupted(self):
        self.assertEqual(run("status"), (0, {"show": False, "dismissed": False, "pending": False}))
        self.assertFalse(self.state.exists(), "status must not create state")

    def test_first_run_after_install_shows(self):
        self.mark_installed()
        self.assertTrue(run("status")[1]["show"])

    def test_dismiss_prevents_showing_again(self):
        self.mark_installed()
        self.assertFalse(run("dismiss")[1]["show"])
        self.assertTrue((self.state / "welcome-dismissed").exists())
        self.assertFalse(run("status")[1]["show"])

    def test_remind_shows_next_login_even_without_installer_record(self):
        self.assertTrue(run("remind")[1]["show"])
        self.assertTrue(run("status")[1]["pending"])
        self.assertEqual(run("dismiss")[1], {"show": False, "dismissed": True, "pending": False})
        self.assertFalse((self.state / "welcome-pending").exists())

    def test_remind_clears_an_earlier_dismissal(self):
        self.mark_installed()
        run("dismiss")
        self.assertEqual(run("remind")[1], {"show": True, "dismissed": False, "pending": True})

    def test_unknown_command_is_rejected(self):
        self.assertEqual(run("reset")[0], 2)
        self.assertEqual(run()[0], 2)


class WelcomePanelTests(unittest.TestCase):
    def setUp(self):
        self.source = (ROOT / "WelcomeMenu.qml").read_text()

    def test_panel_uses_shared_components_and_text_roles(self):
        self.assertIn("\nThemedPopup {", self.source)
        for name in ("PanelButton {", "PanelSwitch {", "PanelStyle.headingSize", "PanelStyle.bodySize",
                     "PanelStyle.secondarySize", "PanelStyle.captionSize", "PanelStyle.padding",
                     "PanelStyle.surfaceInset", "PanelStyle.dividerAlpha", "PanelStyle.fontFamily"):
            self.assertIn(name, self.source)
        self.assertNotIn("HyprlandFocusGrab", self.source)
        self.assertIsNone(re.search(r"pixelSize:\s*\d", self.source), "use PanelStyle text roles")
        self.assertIsNone(re.search(r"#[0-9a-fA-F]{3,8}\b", self.source), "colors must follow the theme")

    def test_panel_has_no_hardcoded_user_paths(self):
        for pattern in ("/home/", "/Users/", "erick", "~/"):
            self.assertNotIn(pattern, self.source)

    def test_panel_steps_reuse_existing_workflows(self):
        kinds = re.findall(r'kind: "(\w+)"', self.source)
        self.assertEqual(kinds, ["theme", "wallpaper", "display", "keyboard", "wifi", "bluetooth", "learn"])
        self.assertIn('"/scripts/appearance-picker.sh"', self.source)
        self.assertIn('"/scripts/show-panel.sh"', self.source)
        self.assertIn('"/walker/bin/walker", "--provider", "menus:learn"', self.source)
        allowlist = re.search(r'case "\$\{1:-\}" in\s*\n\s*([a-z|]+)\)',
                              (ROOT / "scripts/show-panel.sh").read_text()).group(1).split("|")
        for kind in set(kinds) - {"theme", "wallpaper", "learn"}:
            self.assertIn(kind, allowlist)
        self.assertIn("welcome", allowlist)

    def test_shell_registers_centered_welcome_panel(self):
        shell = (ROOT / "shell.qml").read_text()
        self.assertIn("welcome: welcomeMenu", shell)
        self.assertIn("Region { item: welcomeMenu.opened ? welcomeMenu : null }", shell)
        self.assertRegex(shell, r"dockPanels: \[[^\]]*welcomeMenu\]")
        block = shell[shell.index("WelcomeMenu {"):]
        block = block[:block.index("\n                    }\n")]
        self.assertIn("centered: true", block)
        self.assertIn("onAutoShowRequested: bar.showPanel(welcomeMenu)", block)

    def test_walker_learn_menu_opens_welcome(self):
        learn = tomllib.loads((REPO / "elephant/menus/learn.toml").read_text())
        entry = next(entry for entry in learn["entries"] if entry["text"] == "Welcome")
        self.assertEqual(entry["actions"]["open"],
                         "bash $HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh welcome")


if __name__ == "__main__":
    unittest.main()
