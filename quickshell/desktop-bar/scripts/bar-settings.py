#!/usr/bin/env python3
"""Persistent appearance and placement settings for the desktop bar."""

import json
import os
from pathlib import Path
import sys
import tempfile
import subprocess


SETTINGS = Path.home() / ".config/quickshell/desktop-bar/bar-settings.json"
DEFAULTS = {"appearance": "transparent", "layout": "unified", "edge": "top"}
OPTIONS = {
    "appearance": {"none", "transparent", "solid"},
    "layout": {"unified", "split"},
    "edge": {"top", "bottom", "left", "right"},
}


def read_settings():
    try:
        data = json.loads(SETTINGS.read_text(encoding="utf-8"))
    except (FileNotFoundError, ValueError, OSError):
        data = {}
    if not isinstance(data, dict):
        data = {}
    return {
        key: data.get(key) if isinstance(data.get(key), str) and data[key] in choices else DEFAULTS[key]
        for key, choices in OPTIONS.items()
    }


def save_settings(data):
    settings = read_settings()
    for key, value in data.items():
        if key not in OPTIONS or value not in OPTIONS[key]:
            raise ValueError(f"Invalid {key}: {value}")
        settings[key] = value
    SETTINGS.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=".bar-settings-", dir=SETTINGS.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(settings, handle, indent=2)
            handle.write("\n")
        os.replace(temp_name, SETTINGS)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)
    return settings


def main():
    try:
        if sys.argv[1:] == ["status"]:
            result = read_settings()
        elif len(sys.argv) == 3 and sys.argv[1] == "get" and sys.argv[2] in OPTIONS:
            print(read_settings()[sys.argv[2]])
            return 0
        elif len(sys.argv) == 5 and sys.argv[1] == "set-all":
            result = save_settings(dict(zip(DEFAULTS, sys.argv[2:])))
        elif len(sys.argv) == 4 and sys.argv[1] == "set":
            result = save_settings({sys.argv[2]: sys.argv[3]})
            apply_live(sys.argv[2], sys.argv[3])
        elif len(sys.argv) == 3 and sys.argv[1] == "toggle" and sys.argv[2] in {"appearance", "layout"}:
            key = sys.argv[2]
            current = read_settings()[key]
            value = ("transparent" if current == "solid" else "solid") if key == "appearance" else ("unified" if current == "split" else "split")
            result = save_settings({key: value})
            apply_live(key, value)
        else:
            raise ValueError("Usage: bar-settings.py status|set KEY VALUE|set-all APPEARANCE LAYOUT EDGE")
        print(json.dumps(result))
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


def apply_live(key, value):
    try:
        subprocess.run(
            ["qs", "-c", "desktop-bar", "ipc", "call", "--", "bar", "update", key, value],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3, check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        pass


if __name__ == "__main__":
    sys.exit(main())
