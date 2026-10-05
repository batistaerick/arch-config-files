#!/usr/bin/env python3
"""Read subscription limits without starting a conversation or changing accounts."""

import concurrent.futures
import datetime as dt
import glob
import json
import os
from pathlib import Path
import select
import shutil
import subprocess
import time
import urllib.error
import urllib.request


def codex_binary():
    found = shutil.which("codex")
    if found:
        return found
    candidates = glob.glob(str(Path.home() / ".nvm/versions/node/*/bin/codex"))
    if candidates:
        return max(candidates, key=os.path.getmtime)
    raise RuntimeError("Codex CLI is not installed")


def codex_usage():
    binary = codex_binary()
    env = os.environ.copy()
    # NVM's CLI launcher uses /usr/bin/env node; desktop sessions omit its bin dir.
    env["PATH"] = str(Path(binary).parent) + os.pathsep + env.get("PATH", "")
    proc = subprocess.Popen(
        [binary, "-s", "read-only", "-a", "on-request", "app-server"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        env=env,
    )
    pending = b""

    def send(payload):
        proc.stdin.write((json.dumps(payload) + "\n").encode())
        proc.stdin.flush()

    def request(identifier, method, params=None):
        nonlocal pending
        send({"id": identifier, "method": method, "params": params or {}})
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            while b"\n" in pending:
                line, pending = pending.split(b"\n", 1)
                message = json.loads(line)
                if message.get("id") == identifier:
                    if "error" in message:
                        raise RuntimeError("Codex usage unavailable; check `codex login status`")
                    return message.get("result", {})
            if select.select([proc.stdout], [], [], 0.2)[0]:
                chunk = os.read(proc.stdout.fileno(), 65536)
                if not chunk:
                    raise RuntimeError("Codex usage service exited")
                pending += chunk
        raise RuntimeError("Codex usage request timed out")

    try:
        request(1, "initialize", {"clientInfo": {"name": "desktop-ai-usage", "version": "1"}})
        send({"method": "initialized", "params": {}})
        response = request(2, "account/rateLimits/read")
        buckets = response.get("rateLimitsByLimitId") or {"codex": response.get("rateLimits", {})}
        windows = []
        for bucket_id, bucket in buckets.items():
            for key in ("primary", "secondary"):
                window = bucket.get(key)
                if not window or window.get("usedPercent") is None:
                    continue
                minutes = window.get("windowDurationMins", 0)
                label = "Weekly" if minutes == 10080 else f"{minutes // 60}h window" if minutes else "Usage"
                if len(buckets) > 1:
                    label = f"{bucket_id} · {label}"
                windows.append({"label": label, "used": window["usedPercent"], "reset": window.get("resetsAt")})
        return {"name": "Codex", "windows": windows}
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
        proc.stdin.close()
        proc.stdout.close()


def claude_usage():
    home = Path(os.environ.get("CLAUDE_CONFIG_DIR", str(Path.home() / ".claude")))
    try:
        credentials = json.loads((home / ".credentials.json").read_text())
        token = credentials["claudeAiOauth"]["accessToken"]
    except (OSError, ValueError, KeyError):
        raise RuntimeError("Sign in with `claude` to show subscription usage") from None
    request = urllib.request.Request("https://api.anthropic.com/api/oauth/usage", headers={
        "Authorization": "Bearer " + token,
        "anthropic-beta": "oauth-2025-04-20", "Accept": "application/json",
    })
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"Claude usage returned HTTP {exc.code}; retry later or sign in again") from None
    windows = []
    for key, label in (("five_hour", "5h window"), ("seven_day_oauth_apps", "Weekly"),
                       ("seven_day", "Weekly"), ("seven_day_sonnet", "Sonnet weekly"),
                       ("seven_day_opus", "Opus weekly")):
        window = payload.get(key)
        if not window or window.get("utilization") is None:
            continue
        if label == "Weekly" and any(w["label"] == label for w in windows):
            continue
        reset = window.get("resets_at")
        if isinstance(reset, str):
            reset = dt.datetime.fromisoformat(reset.replace("Z", "+00:00")).timestamp()
        windows.append({"label": label, "used": window["utilization"], "reset": reset})
    return {"name": "Claude", "windows": windows}


def collect():
    def safely(name, function):
        try:
            result = function()
            if not result["windows"]:
                result["error"] = "No subscription limits returned"
            return result
        except Exception as exc:
            # Never expose raw HTTP responses or credentials in the display/cache.
            error = str(exc) if isinstance(exc, RuntimeError) else "Could not fetch usage; retry later"
            return {"name": name, "windows": [], "error": error}
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        jobs = [pool.submit(safely, name, fn) for name, fn in (("Codex", codex_usage), ("Claude", claude_usage))]
        return {"updated": time.time(), "providers": [job.result() for job in jobs]}


if __name__ == "__main__":
    print(json.dumps(collect()))
