#!/usr/bin/env python3
import json
import os
import socket
import sys

EVENTS = (
    "workspace",
    "focusedmon",
    "createworkspace",
    "destroyworkspace",
    "moveworkspace",
)


def hypr_dir():
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")

    if signature:
        return os.path.join(runtime_dir, "hypr", signature)

    instances_dir = os.path.join(runtime_dir, "hypr")
    entries = [
        entry
        for entry in os.listdir(instances_dir)
        if os.path.exists(os.path.join(instances_dir, entry, ".socket.sock"))
    ]
    if not entries:
        raise SystemExit("No Hyprland socket found")

    return os.path.join(instances_dir, sorted(entries)[-1])


def request(command):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(os.path.join(hypr_dir(), ".socket.sock"))
        client.sendall(command.encode())
        client.shutdown(socket.SHUT_WR)
        chunks = []
        while True:
            chunk = client.recv(65536)
            if not chunk:
                break
            chunks.append(chunk)
    return b"".join(chunks).decode(errors="replace")


def workspace_status(workspace):
    try:
        active = json.loads(request("j/activeworkspace"))
        active_id = str(active.get("id", ""))
    except Exception:
        active_id = ""

    classes = ["active"] if active_id == workspace else ["empty"]
    return json.dumps({
        "text": workspace,
        "class": classes,
        "tooltip": f"Workspace {workspace}",
    }, separators=(",", ":"))


def status_loop(workspace):
    print(workspace_status(workspace), flush=True)

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as events:
        events.connect(os.path.join(hypr_dir(), ".socket2.sock"))
        with events.makefile("r", encoding="utf-8", errors="replace") as stream:
            for line in stream:
                if line.startswith(EVENTS):
                    print(workspace_status(workspace), flush=True)


def main():
    if len(sys.argv) != 3 or sys.argv[1] != "status":
        raise SystemExit("usage: hypr-workspace.py status <workspace>")

    action, workspace = sys.argv[1], sys.argv[2]
    status_loop(workspace)


if __name__ == "__main__":
    main()
