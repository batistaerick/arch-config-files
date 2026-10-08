#!/usr/bin/env python3
"""Select the screen that hosts the desktop bar."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


CONFIG_DIR = Path.home() / ".config/hypr"
PREFERENCE = CONFIG_DIR / "primary-display"


def active_monitors():
    result = subprocess.run(
        ["hyprctl", "monitors", "-j"], capture_output=True, text=True, check=True
    )
    return json.loads(result.stdout)


def saved_primary():
    try:
        return PREFERENCE.read_text(encoding="utf-8").strip()
    except FileNotFoundError:
        return ""


def choose_primary(monitors, saved="", portable=False):
    connected = {monitor["name"]: monitor for monitor in monitors}
    if saved in connected:
        return saved
    if not connected:
        return ""
    if portable:
        return max(
            monitors,
            key=lambda monitor: (
                monitor["width"] * monitor["height"], monitor.get("refreshRate", 0)
            ),
        )["name"]
    for name in ("HDMI-A-1", "DP-3"):
        if name in connected:
            return name
    return monitors[0]["name"]


def status():
    monitors = active_monitors()
    portable = (CONFIG_DIR / "portable.mode").exists()
    primary = choose_primary(
        monitors, saved_primary(), portable
    )
    return {"monitors": monitors, "primary": primary, "portable": portable}


def set_primary(name):
    if name not in {monitor["name"] for monitor in active_monitors()}:
        raise ValueError("Display is not connected")
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=".primary-display-", dir=CONFIG_DIR)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(name + "\n")
        os.replace(temp_name, PREFERENCE)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)
    return status()


def main():
    try:
        if sys.argv[1:] == ["status"]:
            result = status()
        elif len(sys.argv) == 3 and sys.argv[1] == "set":
            result = set_primary(sys.argv[2])
        else:
            raise ValueError("Usage: display-primary.py status|set DISPLAY")
        print(json.dumps(result))
    except (OSError, subprocess.CalledProcessError, ValueError, KeyError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
