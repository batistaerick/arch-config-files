#!/usr/bin/env python3
"""Control the existing OBS instance without changing scenes or profiles."""
import json
from pathlib import Path
import subprocess
import sys
import time
from urllib.parse import quote


def control(action):
    actions = {
        "record": ["recording", "start"], "stop": ["recording", "stop"],
        "pause": ["recording", "pause"], "resume": ["recording", "resume"],
        "stream": ["streaming", "start"], "stop-stream": ["streaming", "stop"],
    }
    if action not in actions and action != "open":
        raise RuntimeError("Unknown OBS command")
    running = subprocess.run(["pgrep", "-x", "obs"], capture_output=True).returncode == 0
    if action == "open":
        if running:
            subprocess.run(["hyprctl", "dispatch", "focuswindow", "class:^(com.obsproject.Studio)$"], capture_output=True)
        else:
            subprocess.Popen(["obs"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return "Opened OBS"
    if not running and action not in ("record", "stream"):
        raise RuntimeError("OBS is not running")
    config = json.loads((Path.home() / ".config/obs-studio/plugin_config/obs-websocket/config.json").read_text())
    if not config.get("server_enabled"):
        raise RuntimeError("Enable OBS WebSocket in Tools first")
    password = config.get("server_password", "") if config.get("auth_required") else ""
    url = f"obsws://localhost:{config.get('server_port', 4455)}/{quote(password, safe='')}"
    command = ["obs-cmd", "--websocket", url]
    if not running:
        subprocess.Popen(["obs", "--minimize-to-tray"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        for _ in range(30):
            try:
                if subprocess.run(command + ["info"], capture_output=True, timeout=2).returncode == 0:
                    break
            except subprocess.TimeoutExpired:
                pass
            time.sleep(0.5)
        else:
            raise RuntimeError("OBS did not become ready; check its startup window")
    result = subprocess.run(command + actions[action], capture_output=True, timeout=8)
    if result.returncode:
        raise RuntimeError("OBS could not apply that command; check its current state")
    return "Command applied"


if __name__ == "__main__":
    try:
        print(control(sys.argv[1]))
    except Exception as error:
        print(str(error) if isinstance(error, RuntimeError) else "Could not control OBS")
        sys.exit(1)
