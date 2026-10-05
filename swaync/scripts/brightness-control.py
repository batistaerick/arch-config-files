#!/usr/bin/env python3
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(os.environ.get("XDG_RUNTIME_DIR", f"/tmp/runtime-{os.getuid()}")) / "notification-brightness"
ROOT.mkdir(mode=0o700, parents=True, exist_ok=True)


def read(name, default=None):
    try:
        return json.loads((ROOT / name).read_text())
    except (OSError, ValueError):
        return default


def write(name, value):
    temporary = ROOT / f"{name}.{os.getpid()}"
    temporary.write_text(json.dumps(value))
    temporary.replace(ROOT / name)


def launch(mode):
    subprocess.Popen([sys.executable, __file__, mode], stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     start_new_session=True)


def ddc(*args):
    return subprocess.run(["ddcutil", *args], capture_output=True, text=True, timeout=5)


def worker(refresh=False):
    with (ROOT / "lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        pending = read("pending")
        if not refresh and (pending is None or pending == read("applied")):
            return
        state = read("state", {})
        if time.time() - state.get("discovered", 0) > 60:
            detected = ddc("detect", "--brief")
            displays = []
            for block in re.split(r"(?m)^Display ", detected.stdout)[1:]:
                bus = re.search(r"I2C bus:\s+/dev/i2c-(\d+)", block)
                connector = re.search(r"DRM connector:\s+(\S+)", block)
                if bus:
                    displays.append((bus[1], connector[1] if connector else ""))
            if not displays:
                return
            bus, _ = next((item for item in displays if item[1].endswith("HDMI-A-1")), displays[0])
            if state.get("bus") != bus:
                state = {}
            state.update(bus=bus, discovered=time.time())
        if "maximum" not in state or (refresh and time.time() - state.get("updated", 0) > 60):
            result = ddc("--bus", state["bus"], "getvcp", "10", "--brief")
            values = re.search(r"VCP\s+10\s+C\s+(\d+)\s+(\d+)", result.stdout)
            if not values or int(values[2]) == 0:
                return
            current, maximum = map(int, values.groups())
            state.update(maximum=maximum, value=round(current * 100 / maximum), updated=time.time())
            write("state", state)
        # Serialize monitor writes and skip intermediate slider requests.
        while True:
            pending = read("pending")
            if pending is None or pending == read("applied"):
                break
            target = round(pending["value"] * state["maximum"] / 100)
            result = ddc("--bus", state["bus"], "setvcp", "10", str(target), "--noverify")
            if result.returncode:
                state["discovered"] = 0
                write("state", state)
                break
            state.update(value=pending["value"], updated=time.time())
            write("state", state)
            write("applied", pending)


mode = sys.argv[1]
if mode == "get":
    state = read("state", {})
    pending = read("pending")
    print(pending["value"] if pending and pending != read("applied") else state.get("value", 50))
    if time.time() - state.get("updated", 0) > 60:
        launch("refresh")
elif mode == "set":
    try:
        value = max(10, min(100, round(float(sys.argv[2]))))
    except (ValueError, IndexError, OverflowError):
        sys.exit(0)
    write("pending", {"value": value, "request": time.time_ns()})
    launch("apply")
else:
    try:
        worker(mode == "refresh")
    except (OSError, subprocess.TimeoutExpired):
        pass
