#!/usr/bin/env python3
"""Control the existing OBS instance without changing scenes or profiles."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
from urllib.parse import quote


def launch_background():
    result = subprocess.run([
        "hyprctl", "eval",
        'hl.exec_cmd("obs --minimize-to-tray", { workspace = "special:obs-background silent" })',
    ], capture_output=True, timeout=3)
    if result.returncode:
        raise RuntimeError("Could not launch OBS in the background")


def reveal_window():
    clients = subprocess.run(["hyprctl", "-j", "clients"], capture_output=True, text=True, timeout=2)
    if clients.returncode == 0:
        for client in json.loads(clients.stdout):
            if client.get("class") == "com.obsproject.Studio" and client.get("workspace", {}).get("name") == "special:obs-background":
                workspace = subprocess.run(["hyprctl", "-j", "activeworkspace"], capture_output=True, text=True, timeout=2)
                if workspace.returncode == 0:
                    current = json.loads(workspace.stdout)["id"]
                    target = json.dumps("address:" + client["address"])
                    subprocess.run(["hyprctl", "eval", f"hl.dispatch(hl.dsp.window.move({{ workspace = {current}, window = {target}, follow = false }}))"], capture_output=True, timeout=2)
    subprocess.run(["hyprctl", "eval", 'hl.dispatch(hl.dsp.focus({ window = "class:^(com.obsproject.Studio)$" }))'], capture_output=True)


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


def close_if_idle():
    state = status()
    for _ in range(10):
        if not state["ready"] or state["streaming"] or not state["recording"]:
            break
        time.sleep(0.25)
        state = status()
    if not state["ready"] or not state["running"] or state["recording"] or state["streaming"]:
        return False
    processes = subprocess.run(["pgrep", "-x", "obs"], capture_output=True, text=True)
    pids = processes.stdout.split()
    # WebSocket controls one instance; never close unrelated OBS instances.
    if processes.returncode or len(pids) != 1 or not pids[0].isdigit():
        return False
    pid = int(pids[0])
    clients = subprocess.run(["hyprctl", "-j", "clients"], capture_output=True, text=True, timeout=2)
    if clients.returncode == 0:
        for client in json.loads(clients.stdout):
            if client.get("pid") == pid and client.get("class") == "com.obsproject.Studio":
                target = json.dumps("address:" + client["address"])
                result = subprocess.run(["hyprctl", "eval", f"hl.dispatch(hl.dsp.window.close({{ window = {target} }}))"], capture_output=True, timeout=2)
                if result.returncode == 0:
                    return True
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    return True


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
    if not running:
        launch_background()
        for _ in range(30):
            try:
                if subprocess.run(command + ["info"], capture_output=True, timeout=2).returncode == 0:
                    break
            except subprocess.TimeoutExpired:
                pass
            time.sleep(0.5)
        else:
            raise RuntimeError("OBS did not become ready; check its startup window")
    result = subprocess.run(command + actions[action], capture_output=True, timeout=30 if action in {"stop", "stop-stream"} else 8)
    if result.returncode:
        raise RuntimeError("OBS could not apply that command; check its current state")
    if action in {"stop", "stop-stream"}:
        close_if_idle()
    return "Command applied"


if __name__ == "__main__":
    try:
        print(json.dumps(status()) if sys.argv[1] == "status" else control(sys.argv[1]))
    except Exception as error:
        print(str(error) if isinstance(error, RuntimeError) else "Could not control OBS")
        sys.exit(1)
