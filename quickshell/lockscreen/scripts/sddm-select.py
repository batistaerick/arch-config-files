#!/usr/bin/python3 -I
"""Privileged selector: accepts only IDs in the root-owned installed manifest."""
import json
import os
from pathlib import Path
import sys
import tempfile

MANIFEST = Path('/usr/local/share/desktop-lockscreen/designs.json')
CONFIG = Path('/etc/sddm.conf.d/90-desktop-lockscreen.conf')


def main():
    if os.geteuid() != 0 or len(sys.argv) != 2:
        raise SystemExit('Usage: desktop-login-select DESIGN (requires root)')
    designs = json.loads(MANIFEST.read_text())
    theme = designs.get(sys.argv[1])
    if not isinstance(theme, str) or not theme.startswith('desktop-lockscreen-') or any(
        character not in 'abcdefghijklmnopqrstuvwxyz0123456789-' for character in theme
    ):
        raise SystemExit('Unknown installed login design')
    if not (Path('/usr/share/sddm/themes') / theme / 'Main.qml').is_file():
        raise SystemExit('Login design is not installed')
    CONFIG.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix='.desktop-lockscreen-', dir=CONFIG.parent)
    try:
        with os.fdopen(fd, 'w') as output:
            output.write('[Theme]\nCurrent=' + theme + '\n')
            output.flush()
            os.fsync(output.fileno())
            os.fchmod(output.fileno(), 0o644)
        os.replace(temporary, CONFIG)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == '__main__':
    main()
