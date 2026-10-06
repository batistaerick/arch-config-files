#!/usr/bin/env python3
"""Read and control iwd without parsing terminal output."""
import json
from pathlib import Path
import re
import subprocess
import sys
import time

from gi.repository import Gio, GLib

SERVICE = "net.connman.iwd"
PREFIX = SERVICE + "."
bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)


def call(path, interface, method, parameters=None):
    return bus.call_sync(SERVICE, path, interface, method, parameters, None,
                         Gio.DBusCallFlags.NONE, 10000, None).unpack()


def snapshot():
    objects = call("/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects")[0]
    devices = []
    for path, interfaces in objects.items():
        device = interfaces.get(PREFIX + "Device")
        if not device or device.get("Mode") != "station":
            continue
        station = interfaces.get(PREFIX + "Station", {})
        networks = []
        if device.get("Powered") and station:
            for network_path, strength in call(path, PREFIX + "Station", "GetOrderedNetworks")[0]:
                network = objects.get(network_path, {}).get(PREFIX + "Network", {})
                networks.append({"path": network_path, "name": network.get("Name", "Hidden network"),
                                 "type": network.get("Type", ""), "known": bool(network.get("KnownNetwork")),
                                 "connected": station.get("ConnectedNetwork") == network_path,
                                 "strength": max(0, min(100, 2 * (strength / 100 + 100)))})
        details = telemetry(device["Name"])
        details["automatic"] = not station.get("Affinities")
        if station.get("State") == "connected":
            try:
                diagnostic = call(path, PREFIX + "StationDiagnostic", "GetDiagnostics")[0]
                frequency = diagnostic.get("Frequency", 0)
                details["band"] = "6 GHz" if frequency >= 5925 else "5 GHz" if frequency >= 4900 else "2.4 GHz"
            except GLib.Error:
                pass
        devices.append({"path": path, "name": device["Name"], "powered": device.get("Powered", False),
                        "state": station.get("State", "off"), "scanning": station.get("Scanning", False),
                        "networks": networks, "details": details})
    return {"devices": devices}


def telemetry(interface):
    result = {"sampled": time.monotonic()}
    for key, counter in (("rx", "rx_bytes"), ("tx", "tx_bytes")):
        try:
            result[key] = int((Path("/sys/class/net") / interface / "statistics" / counter).read_text())
        except OSError:
            pass
    try:
        addresses = json.loads(subprocess.check_output(["ip", "-j", "-4", "addr", "show", "dev", interface], timeout=2))
        result["ip"] = next((a["local"] for link in addresses for a in link.get("addr_info", []) if a.get("scope") == "global"), "")
        routes = json.loads(subprocess.check_output(["ip", "-j", "-4", "route", "show", "default", "dev", interface], timeout=2))
        result["gateway"] = next((r["gateway"] for r in routes if r.get("gateway")), "")
    except (OSError, GLib.Error, subprocess.SubprocessError, ValueError):
        pass
    return result


def probe(interface):
    result = subprocess.run(["ping", "-n", "-I", interface, "-c", "2", "-W", "1", "1.1.1.1"],
                            capture_output=True, text=True, timeout=4, env={"PATH": "/usr/bin", "LC_ALL": "C"})
    loss = re.search(r"([\d.]+)% packet loss", result.stdout)
    timing = re.search(r"= [\d.]+/([\d.]+)/", result.stdout)
    return {"loss": float(loss[1]) if loss else None, "ping": float(timing[1]) if timing else None}


def connect(path, password):
    # iwd asks the temporary agent for secrets on this same bus connection.
    xml = '''<node><interface name="net.connman.iwd.Agent">
      <method name="Release"/><method name="Cancel"><arg type="s" direction="in"/></method>
      <method name="RequestPassphrase"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
      <method name="RequestPrivateKeyPassphrase"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
      <method name="RequestUserNameAndPassword"><arg type="o" direction="in"/><arg type="s" direction="out"/><arg type="s" direction="out"/></method>
      <method name="RequestUserPassword"><arg type="o" direction="in"/><arg type="s" direction="in"/><arg type="s" direction="out"/></method>
    </interface></node>'''
    def agent(connection, sender, object_path, interface, method, parameters, invocation):
        if method in ("Release", "Cancel"):
            invocation.return_value(None)
        elif method == "RequestPassphrase" and password:
            invocation.return_value(GLib.Variant("(s)", (password,)))
        else:
            invocation.return_dbus_error(PREFIX + "Error.Canceled", "Credentials required")

    agent_path = "/desktop_bar/wifi_agent"
    registration = bus.register_object(agent_path, Gio.DBusNodeInfo.new_for_xml(xml).interfaces[0], agent, None, None)
    call("/net/connman/iwd", PREFIX + "AgentManager", "RegisterAgent", GLib.Variant("(o)", (agent_path,)))
    loop = GLib.MainLoop()
    errors = []
    def finished(connection, result):
        try:
            connection.call_finish(result)
        except GLib.Error as error:
            errors.append(error.message)
        loop.quit()
    try:
        bus.call(SERVICE, path, PREFIX + "Network", "Connect", None, None,
                 Gio.DBusCallFlags.NONE, 45000, None, finished)
        loop.run()
    finally:
        call("/net/connman/iwd", PREFIX + "AgentManager", "UnregisterAgent", GLib.Variant("(o)", (agent_path,)))
        bus.unregister_object(registration)
    if errors:
        raise RuntimeError(errors[0])


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "status"
    if action == "status":
        return snapshot()
    if action == "probe":
        return probe(sys.argv[2])
    path = sys.argv[2]
    if action == "connect":
        request = json.loads(sys.stdin.readline())
        connect(path, request.get("password", ""))
    elif action in ("scan", "disconnect"):
        call(path, PREFIX + "Station", action.capitalize())
    elif action == "power":
        call(path, "org.freedesktop.DBus.Properties", "Set",
             GLib.Variant("(ssv)", (PREFIX + "Device", "Powered", GLib.Variant("b", sys.argv[3] == "true"))))
    else:
        raise ValueError("Unknown action")
    return {"ok": True}


if __name__ == "__main__":
    try:
        print(json.dumps(main()))
    except (GLib.Error, RuntimeError, ValueError, IndexError, OSError, subprocess.SubprocessError) as error:
        print(json.dumps({"error": str(error)}))
        sys.exit(1)
