#!/usr/bin/env python3
import configparser
import json
from pathlib import Path
import sys
import subprocess

ROOT = Path(__file__).resolve().parents[1]
STATE = Path.home() / ".config/lockscreen/selected"
NAMES = {"material-you": "Material Light", "material-you-dark": "Material Dark",
         "nothing": "Nothing", "clockwork/orbital": "Clockwork Orbital",
         "clockwork/neo-orbital": "Clockwork Neo Orbital", "clockwork/tape": "Clockwork Tape",
         "pixel-coffee": "Pixel · Coffee", "pixel-dusk-city": "Pixel · Dusk City",
         "pixel-hollowknight": "Pixel · Hollow Knight", "pixel-night-city": "Pixel · Night City",
         "enfield": "Enfield", "sword": "Sword", "forest": "Forest", "winter": "Winter",
         "last-of-us": "The Last of Us", "field": "Field", "girl-coffee": "Girl · Coffee",
         "girl-pillow": "Girl · Pillow", "nier-automata": "NieR: Automata"}


def designs():
    return {
        str(path.parent.relative_to(ROOT / "themes")): NAMES.get(str(path.parent.relative_to(ROOT / "themes")), path.parent.name)
        for path in sorted((ROOT / "themes").rglob("Main.qml"))}


def selected():
    try:
        value = STATE.read_text().strip()
    except OSError:
        value = "hyprlock"
    return value if value in designs() else "hyprlock"


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "current"
    if command == "current":
        print(selected())
        return
    if command == "list":
        for value, label in designs().items():
            print(f"{value}\t{label}")
        return
    value = sys.argv[2]
    if value not in designs():
        raise SystemExit("Unknown lockscreen")
    if command == "select":
        helper = Path('/usr/local/bin/desktop-login-select')
        if helper.is_file():
            result = subprocess.run(['sudo', '-n', str(helper), value], capture_output=True, text=True)
            if result.returncode:
                raise SystemExit('Login screen could not be updated: ' + result.stderr.strip())
        STATE.parent.mkdir(parents=True, exist_ok=True)
        temporary = STATE.with_suffix(".tmp")
        temporary.write_text(value + "\n")
        temporary.replace(STATE)
    elif command == "config":
        parser = configparser.ConfigParser(interpolation=None, strict=False)
        parser.optionxform = str
        parser.read(ROOT / "themes" / value / "theme.conf")
        print(json.dumps(dict(parser["General"]) if parser.has_section("General") else {}))
    else:
        raise SystemExit("Unknown command")


if __name__ == "__main__":
    main()
