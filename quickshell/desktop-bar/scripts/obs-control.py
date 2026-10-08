#!/usr/bin/env python3
"""Control the existing OBS instance without changing scenes or profiles."""
import json
from pathlib import Path
import subprocess
import sys
import time
from urllib.parse import quote


def background_window(pid):
    """Keep a newly launched OBS window off the active workspace if no tray hosts it."""
    result = subprocess.run(["hyprctl", "-j", "clients"], capture_output=True, text=True, timeout=2)
    if result.returncode:
        return
    for client in json.loads(result.stdout):
        if client.get("pid") == pid and client.get("class") == "com.obsproject.Studio":
            subprocess.run(["hyprctl", "dispatch", "movetoworkspacesilent", "special:obs-background,address:" + client["address"]], capture_output=True, timeout=2)


def reveal_window():
    clients = subprocess.run(["hyprctl", "-j", "clients"], capture_output=True, text=True, timeout=2)
    if clients.returncode == 0:
        for client in json.loads(clients.stdout):
            if client.get("class") == "com.obsproject.Studio" and client.get("workspace", {}).get("name") == "special:obs-background":
                workspace = subprocess.run(["hyprctl", "-j", "activeworkspace"], capture_output=True, text=True, timeout=2)
                if workspace.returncode == 0:
                    current = json.loads(workspace.stdout)["id"]
                    subprocess.run(["hyprctl", "dispatch", "movetoworkspacesilent", f"{current},address:{client['address']}"], capture_output=True, timeout=2)
    subprocess.run(["hyprctl", "dispatch", "focuswindow", "class:^(com.obsproject.Studio)$"], capture_output=True)


def websocket_command():
    config = json.loads((Path.home() / ".config/obs-studio/plugin_config/obs-websocket/config.json").read_text())
    if not config.get("server_enabled"):
        raise RuntimeError("Enable OBS WebSocket in Tools first")
    password = config.get("server_password", "") if config.get("auth_required") else ""
    url = f"obsws://localhost:{config.get('server_port', 4455)}/{quote(password, safe='')}"
    return ["obs-cmd", "--websocket", url]


def parse_status(text):
    fields = dict(line.strip().split(":", 1) for line in text.splitlines() if ":" in line)
    active = fields.get("Active", "").strip().lower()
    if active not in {"true", "false"}:
        raise RuntimeError("OBS status unavailable")
    paused = fields.get("Paused", "false").strip().lower()
    if active == "true" and paused not in {"true", "false"}:
        raise RuntimeError("OBS pause status unavailable")
    return {"active": active == "true", "paused": paused == "true"}


def status():
    state = {"running": False, "ready": True, "recording": False, "paused": False, "streaming": False}
    if subprocess.run(["pgrep", "-x", "obs"], capture_output=True).returncode != 0:
        return state
    state.update(running=True, ready=False)
    try:
        command = websocket_command()
        for kind in ("recording", "streaming"):
            result = subprocess.run(command + [kind, "status"], capture_output=True, text=True, timeout=3)
            if result.returncode:
                raise RuntimeError("Could not read OBS status")
            parsed = parse_status(result.stdout)
            state[kind] = parsed["active"]
            if kind == "recording":
                state["paused"] = parsed["paused"]
        state["ready"] = True
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        state["error"] = str(error) if isinstance(error, RuntimeError) else "Could not read OBS status"
    return state


def control(action):
    actions = {
        "record": ["recording", "start"], "stop": ["recording", "stop"],
        "pause": ["recording", "pause"], "resume": ["recording", "resume"],
        "stream": ["streaming", "start"], "stop-stream": ["streaming", "stop"],
    }
    if action == "folder":
        directory = Path.home() / "Videos/Records"
        directory.mkdir(parents=True, exist_ok=True)
        subprocess.Popen(["xdg-open", str(directory)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return ""
    if action not in actions and action != "open":
        raise RuntimeError("Unknown OBS command")
    running = subprocess.run(["pgrep", "-x", "obs"], capture_output=True).returncode == 0
    if action == "open":
        if running:
            reveal_window()
        else:
            subprocess.Popen(["obs"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return "Opened OBS"
    if not running and action not in ("record", "stream"):
        raise RuntimeError("OBS is not running")
    command = websocket_command()
    launched = None
    if not running:
        launched = subprocess.Popen(["obs", "--minimize-to-tray"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        for _ in range(30):
            try:
                if subprocess.run(command + ["info"], capture_output=True, timeout=2).returncode == 0:
                    break
            except subprocess.TimeoutExpired:
                pass
            time.sleep(0.5)
        else:
            raise RuntimeError("OBS did not become ready; check its startup window")
        background_window(launched.pid)
    result = subprocess.run(command + actions[action], capture_output=True, timeout=8)
    if result.returncode:
        raise RuntimeError("OBS could not apply that command; check its current state")
    return "Command applied"


if __name__ == "__main__":
    try:
        print(json.dumps(status()) if sys.argv[1] == "status" else control(sys.argv[1]))
    except Exception as error:
        print(str(error) if isinstance(error, RuntimeError) else "Could not control OBS")
        sys.exit(1)
