from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class PanelLayeringTests(unittest.TestCase):
    def test_open_and_closing_panels_use_foreground_layer(self):
        shell = (ROOT / "shell.qml").read_text()
        self.assertIn("readonly property bool panelOpen: dockPanels.some(panel => panel.visible)", shell)
        self.assertIn("WlrLayershell.layer: panelOpen && !notificationPopups.visible ? WlrLayer.Overlay : WlrLayer.Top", shell)
        self.assertIn("Region { item: notificationCenter.opened ? notificationCenter : null }", shell)
        dock = (ROOT / "DockPanel.qml").read_text()
        self.assertIn("visible: opened || revealProgress > 0", dock)

    def test_notification_popups_also_use_overlay(self):
        shell = (ROOT / "shell.qml").read_text()
        self.assertIn("id: notificationPopups", shell)
        self.assertIn("panelOpen && !notificationPopups.visible", shell)
        self.assertIn("WlrLayershell.layer: WlrLayer.Overlay",
                      (ROOT / "NotificationPopups.qml").read_text())
