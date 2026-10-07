import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("wifi", Path(__file__).parents[1] / "scripts/wifi-popup.py")
wifi = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wifi)


class KnownNetworkTests(unittest.TestCase):
    def setUp(self):
        self.saved = {"/known": {wifi.PREFIX + "KnownNetwork": {"Name": "Hotspot", "Type": "psk"}}}

    def test_offline_saved_network_remains(self):
        row = wifi.merge_known([], self.saved)[0]
        self.assertTrue(row["known"])
        self.assertFalse(row["available"])
        self.assertIsNone(row["strength"])
        self.assertEqual(row["knownPath"], "/known")

    def test_visible_saved_network_is_not_duplicated(self):
        visible = [{"name": "Hotspot", "type": "psk", "known": False, "connected": True, "strength": 80, "path": "/network"}]
        rows = wifi.merge_known(visible, self.saved)
        self.assertEqual(len(rows), 1)
        self.assertTrue(rows[0]["known"])
        self.assertTrue(rows[0]["available"])
        self.assertEqual(rows[0]["knownPath"], "/known")
        self.assertFalse(visible[0]["known"])

    def test_same_ssid_different_security_is_distinct(self):
        visible = [{"name": "Hotspot", "type": "open", "known": False, "connected": False, "strength": 80, "path": "/network"}]
        self.assertEqual(len(wifi.merge_known(visible, self.saved)), 2)
