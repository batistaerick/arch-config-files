#!/usr/bin/env python3
"""Laptop battery charge limit; changes only after typed confirmation."""
from pathlib import Path
import subprocess
import sys

ROOT_HELPER = "/usr/local/lib/eitr/eitr-system"


def valid_limit(value):
    return value == "off" or (value.isdigit() and 60 <= int(value) <= 100)


def main(args):
    if not Path(ROOT_HELPER).exists():
        raise RuntimeError("The root-owned Eitr helper is not installed. See distro/README.md; never sudo a user-writable helper.")
    if args == ["status"]:
        # Reading sysfs thresholds needs no privileges.
        subprocess.run([ROOT_HELPER, "battery-limit-status"], check=False)
        return
    if len(args) != 2 or args[0] != "set" or not valid_limit(args[1]):
        raise ValueError("Usage: battery-limit.py status | set <60-100|off>")
    value = args[1]
    if value == "off":
        print("This removes the charge limit, so the battery charges to 100%.")
    else:
        print(f"Charging will stop at {value}% to reduce battery wear, also after reboot and resume.")
        print("Only firmware that exposes charge_control_end_threshold supports this.")
    if input("Type yes to apply (anything else cancels): ") != "yes":
        return
    subprocess.run(["sudo", ROOT_HELPER, "battery-limit", value], check=True)


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
