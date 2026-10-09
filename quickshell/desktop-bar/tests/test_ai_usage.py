import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("ai_usage", ROOT / "scripts/ai-usage.py")
USAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(USAGE)


class ClaudeLimitsTests(unittest.TestCase):
    def test_fable_scoped_weekly_limit_and_legacy_deduplication(self):
        result = USAGE.claude_windows({
            "five_hour": {"utilization": 20, "resets_at": None},
            "seven_day": {"utilization": 30},
            "limits": [
                {"kind": "session", "percent": 20},
                {"kind": "weekly_all", "percent": 30},
                {"kind": "weekly_scoped", "percent": 10, "is_active": False,
                 "scope": {"model": {"display_name": "Fable"}},
                 "resets_at": "2026-10-14T12:00:00Z"},
            ],
        })
        self.assertEqual([row["label"] for row in result], ["5h window", "Weekly", "Fable weekly"])
        self.assertEqual(result[-1]["used"], 10)
        self.assertIsInstance(result[-1]["reset"], float)

    def test_missing_and_future_limits_do_not_invent_usage(self):
        self.assertEqual(USAGE.claude_windows({"limits": [{"kind": "unknown", "percent": 9},
                                                      {"kind": "weekly_scoped", "percent": None}]}), [])

    def test_token_details_reset_without_persistence(self):
        qml = (ROOT / "AiUsageMenu.qml").read_text()
        self.assertIn("property bool detailsExpanded: false", qml)
        self.assertIn("visible: menu.detailsExpanded", qml)
        self.assertIn("onOpenedChanged: if (opened) {\n        detailsExpanded = false;", qml)
        self.assertNotIn("Math.max(678", qml)
