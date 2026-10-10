#!/usr/bin/env python3
"""Control the existing OBS instance without changing scenes or profiles."""
import json
import configparser
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
from urllib.parse import quote


OPTIONS_FILE = Path.home() / ".config/quickshell/desktop-bar/obs-recording.json"


def scene_collection():
    config = configparser.ConfigParser(interpolation=None)
    config.read(Path.home() / ".config/obs-studio/user.ini")
    collection = Path(config.get("Basic", "SceneCollectionFile", fallback="Untitled.json")).name
    if not collection.endswith(".json"):
        collection += ".json"
    try:
        return json.loads((Path.home() / ".config/obs-studio/basic/scenes" / collection).read_text())
    except (OSError, ValueError):
        return {}


def capture_options():
    scene = scene_collection()
    sources = list(scene.get("sources", [])) + [value for value in scene.values() if isinstance(value, dict) and value.get("id")]
    roles = {
        "audio": [source for source in sources if source.get("id") in {"pulse_output_capture", "wasapi_output_capture"}],
        "mic": [source for source in sources if source.get("id") in {"pulse_input_capture", "wasapi_input_capture"}],
        "webcam": [source for source in sources if source.get("id") in {"v4l2_input", "av_capture_input", "dshow_input"}],
    }
    try:
        saved = json.loads(OPTIONS_FILE.read_text())
    except (OSError, ValueError):
        saved = {}
    if not isinstance(saved, dict):
        saved = {}
    result = {}
    for key, inputs in roles.items():
        default = any(not source.get("muted", False) for source in inputs) if key != "webcam" else False
        enabled = saved.get(key) if isinstance(saved.get(key), bool) else default
        result[key] = {"enabled": enabled, "available": bool(inputs), "sources": [source["name"] for source in inputs]}
    return result


def save_capture_option(key, value):
    if key not in {"audio", "mic", "webcam"} or value not in {"true", "false"}:
        raise RuntimeError("Invalid recording option")
    options = capture_options()
    if value == "true" and not options[key]["available"]:
        raise RuntimeError("Configure this source in OBS first")
    saved = {name: option["enabled"] for name, option in options.items()}
    saved[key] = value == "true"
    OPTIONS_FILE.parent.mkdir(parents=True, exist_ok=True)
    temporary = OPTIONS_FILE.with_suffix(".tmp")
    temporary.write_text(json.dumps(saved, indent=2) + "\n")
    temporary.replace(OPTIONS_FILE)
    return capture_options()


def apply_capture_options(command):
    scene = scene_collection()
    sources = {source.get("name"): source for source in scene.get("sources", [])}
    active_scene = sources.get(scene.get("current_scene"), {})
    visible = {item.get("name") for item in active_scene.get("settings", {}).get("items", []) if item.get("visible", True)}
    if not any(source.get("id") == "pipewire-screen-capture-source" and name in visible for name, source in sources.items()):
        raise RuntimeError("Set up full-screen monitor capture in OBS first")
    options = capture_options()
    for key in ("audio", "mic"):
        for name in options[key]["sources"]:
            result = subprocess.run(command + ["audio", "unmute" if options[key]["enabled"] else "mute", name], capture_output=True, timeout=3)
            if result.returncode:
                raise RuntimeError("Could not apply recording audio settings")
    cameras = options["webcam"]
    if cameras["sources"]:
        current = subprocess.run(command + ["scene", "current"], capture_output=True, text=True, timeout=3)
        if current.returncode:
            raise RuntimeError("Could not read the current OBS scene")
        scene = next((line.removeprefix("Current scene:").strip()
                      for line in current.stdout.splitlines()
                      if line.startswith("Current scene:")), "")
        if not scene:
            raise RuntimeError("Could not read the current OBS scene")
        for name in cameras["sources"]:
            result = subprocess.run(command + ["scene-item", "enable" if cameras["enabled"] else "disable", scene, name], capture_output=True, timeout=3)
            if result.returncode:
                raise RuntimeError("Could not apply recording webcam settings")


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


WEBSOCKET_ENV = "OBS_WEBSOCKET_URL"


def websocket_command():
    """Return the obs-cmd command and export its connection URL.

    The URL contains the WebSocket password, so it is passed through this
    process's environment (inherited by obs-cmd children) instead of argv,
    which other local users can read from the process list.
    """
    config = json.loads((Path.home() / ".config/obs-studio/plugin_config/obs-websocket/config.json").read_text())
    if not config.get("server_enabled"):
        raise RuntimeError("Enable OBS WebSocket in Tools first")
    password = config.get("server_password", "") if config.get("auth_required") else ""
    os.environ[WEBSOCKET_ENV] = f"obsws://localhost:{config.get('server_port', 4455)}/{quote(password, safe='')}"
    return ["obs-cmd"]


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
    if action not in actions and action not in {"open", "prepare"}:
        raise RuntimeError("Unknown OBS command")
    running = subprocess.run(["pgrep", "-x", "obs"], capture_output=True).returncode == 0
    if action == "open":
        if running:
            reveal_window()
        else:
            subprocess.Popen(["obs"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return "Opened OBS"
    if not running and action not in ("record", "stream", "prepare"):
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
    if action == "prepare":
        apply_capture_options(command)
        return "OBS ready"
    result = subprocess.run(command + actions[action], capture_output=True, timeout=30 if action in {"stop", "stop-stream"} else 8)
    if result.returncode:
        raise RuntimeError("OBS could not apply that command; check its current state")
    if action in {"stop", "stop-stream"}:
        close_if_idle()
    return "Command applied"


if __name__ == "__main__":
    try:
        action = sys.argv[1]
        if action == "options":
            print(json.dumps(capture_options()))
        elif action == "set-option":
            print(json.dumps(save_capture_option(sys.argv[2], sys.argv[3])))
        else:
            print(json.dumps(status()) if action == "status" else control(action))
    except Exception as error:
        print(str(error) if isinstance(error, RuntimeError) else "Could not control OBS")
        sys.exit(1)
