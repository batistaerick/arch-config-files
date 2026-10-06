#!/usr/bin/env python3
"""Summarize local CLI token records without retaining conversation content."""
import datetime as dt
import fcntl
import json
import os
from pathlib import Path
import tempfile


def day(timestamp, fallback):
    try:
        value = dt.datetime.fromisoformat(str(timestamp).replace("Z", "+00:00"))
        return value.astimezone().date().isoformat()
    except (ValueError, TypeError):
        return dt.datetime.fromtimestamp(fallback).date().isoformat()


def number(value):
    try:
        return max(0, int(value or 0))
    except (TypeError, ValueError):
        return 0


def read_records(path, provider):
    records = {}
    model = "Codex"
    previous_total = None
    seen_meta = False
    modified = path.stat().st_mtime
    with path.open("rb") as handle:
        for index, raw in enumerate(handle):
            if not raw.endswith(b"\n"):
                break
            if provider == "Claude" and b'"usage"' not in raw:
                continue
            if provider == "Codex" and not any(key in raw for key in (b'"token_count"', b'"turn_context"', b'"session_meta"')):
                continue
            try:
                entry = json.loads(raw)
            except (ValueError, UnicodeError):
                continue
            if not isinstance(entry, dict):
                continue
            if provider == "Claude":
                message = entry.get("message") or {}
                if not isinstance(message, dict) or (entry.get("type") != "assistant" and message.get("role") != "assistant"):
                    continue
                usage = message.get("usage") or entry.get("usage")
                if not isinstance(usage, dict):
                    continue
                key = str(message.get("id") or entry.get("messageId") or f"{path}:{entry.get('uuid') or index}")
                model = str(message.get("model") or entry.get("model") or "Claude")
                tokens = sum(number(usage.get(snake, usage.get(camel))) for snake, camel in (
                    ("input_tokens", "inputTokens"), ("output_tokens", "outputTokens"),
                    ("cache_read_input_tokens", "cacheReadInputTokens"), ("cache_creation_input_tokens", "cacheCreationInputTokens")))
                output = number(usage.get("output_tokens", usage.get("outputTokens")))
                timestamp = entry.get("timestamp") or message.get("timestamp")
            else:
                payload = entry.get("payload") or {}
                if not isinstance(payload, dict):
                    continue
                if entry.get("type") == "session_meta":
                    if not seen_meta:
                        seen_meta = True
                        if payload.get("model_provider") not in (None, "", "openai"):
                            return {}
                    continue
                if entry.get("type") == "turn_context":
                    model = str(payload.get("model") or payload.get("model_slug") or model)
                    continue
                if payload.get("type") != "token_count":
                    continue
                info = payload.get("info") or {}
                usage = info.get("last_token_usage") or {}
                total = info.get("total_token_usage")
                # Quota-only events repeat the last turn. Cached/reasoning
                # tokens are already included in input/output respectively.
                if total and total == previous_total:
                    continue
                previous_total = total
                tokens = number(usage.get("input_tokens")) + number(usage.get("output_tokens"))
                output = number(usage.get("output_tokens"))
                key = f"{path}:{index}"
                timestamp = entry.get("timestamp")
            if not tokens:
                continue
            record = [model, day(timestamp, modified), tokens, output]
            if key not in records or output >= records[key][3]:
                records[key] = record
    return records


def summarize(records):
    today = dt.date.today()
    days = {(today - dt.timedelta(days=i)).isoformat(): 0 for i in range(6, -1, -1)}
    models = {}
    for model, date, tokens, output in records.values():
        models[model] = models.get(model, 0) + tokens
        if date in days:
            days[date] += tokens
    return {"days": [{"date": date, "tokens": tokens} for date, tokens in days.items()],
            "models": [{"name": name, "tokens": tokens} for name, tokens in sorted(models.items(), key=lambda pair: -pair[1])]}


def collect(home=None, cache=None):
    home = Path(home or Path.home())
    cache = Path(cache or home / ".cache/desktop-ai-local-stats")
    cache.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (cache / "scan.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            previous = json.loads((cache / "files.json").read_text())
        except (OSError, ValueError):
            previous = {}
        files, result = {}, {}
        roots = {"Codex": Path(os.environ.get("CODEX_HOME", home / ".codex")) / "sessions",
                 "Claude": Path(os.environ.get("CLAUDE_CONFIG_DIR", home / ".claude")) / "projects"}
        for provider, root in roots.items():
            records = {}
            for path in sorted(root.rglob("*.jsonl")):
                try:
                    stat = path.stat()
                    fingerprint = [stat.st_size, stat.st_mtime_ns, stat.st_ino]
                    key = str(path)
                    held = previous.get(key, {})
                    if held.get("fingerprint") == fingerprint:
                        parsed = held["records"]
                    else:
                        parsed = read_records(path, provider)
                    after = path.stat()
                    if fingerprint == [after.st_size, after.st_mtime_ns, after.st_ino]:
                        files[key] = {"fingerprint": fingerprint, "records": parsed}
                    for identifier, record in parsed.items():
                        if identifier not in records or record[3] >= records[identifier][3]:
                            records[identifier] = record
                except (OSError, ValueError, KeyError, TypeError):
                    continue
            result[provider] = summarize(records)
        with tempfile.NamedTemporaryFile(mode="w", dir=cache, delete=False) as temporary:
            json.dump(files, temporary)
        os.replace(temporary.name, cache / "files.json")
        return result


if __name__ == "__main__":
    print(json.dumps(collect()))
