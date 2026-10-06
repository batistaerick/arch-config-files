import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

path = Path(__file__).parents[1] / "scripts/ai-local-stats.py"
spec = importlib.util.spec_from_file_location("local_stats", path)
stats = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stats)


class TokenRecordsTest(unittest.TestCase):
    def records(self, provider, entries):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "session.jsonl"
            path.write_text("".join(json.dumps(entry) + "\n" for entry in entries))
            return stats.read_records(path, provider)

    def test_claude_streaming_replaces_snapshot_without_double_counting(self):
        def entry(output):
            return {"type": "assistant", "timestamp": "2026-10-06T15:00:00Z", "message": {
                "id": "one-response", "model": "claude-test", "usage": {
                    "input_tokens": 20, "output_tokens": output,
                    "cache_read_input_tokens": 30, "cache_creation_input_tokens": 10}}}
        records = self.records("Claude", [entry(0), entry(7), entry(3), entry(7)])
        self.assertEqual(len(records), 1)
        self.assertEqual(records["one-response"][2:], [67, 7])

    def test_codex_quota_duplicates_and_cached_tokens(self):
        def event(total):
            return {"type": "event_msg", "payload": {"type": "token_count", "info": {
                "last_token_usage": {"input_tokens": 100, "cached_input_tokens": 80, "output_tokens": 10, "reasoning_output_tokens": 5},
                "total_token_usage": {"total_tokens": total}}}}
        records = self.records("Codex", [event(110), event(110), event(220), event(110)])
        self.assertEqual(len(records), 3)
        self.assertEqual(sum(record[2] for record in records.values()), 330)

    def test_codex_foreign_provider_is_not_subscription_usage(self):
        records = self.records("Codex", [
            {"type": "session_meta", "payload": {"model_provider": "ollama"}},
            {"type": "event_msg", "payload": {"type": "token_count", "info": {"last_token_usage": {"input_tokens": 10}}}}])
        self.assertEqual(records, {})

    def test_partial_json_and_missing_roots(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "partial.jsonl"
            path.write_text('{"type": "assistant", "message":')
            self.assertEqual(stats.read_records(path, "Claude"), {})
            result = stats.collect(Path(folder), Path(folder) / "cache")
            self.assertEqual(len(result["Claude"]["days"]), 7)
            self.assertEqual(result["Codex"]["models"], [])


if __name__ == "__main__":
    unittest.main()
