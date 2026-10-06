#!/usr/bin/env python3
import json
from pathlib import Path
import sys

STYLES = ('Numbers', 'Glyph', 'Kanji', 'Aurora', 'Pacman')
STATE = Path.home() / '.config/quickshell/desktop-bar/workspace-style.json'

if len(sys.argv) != 2 or sys.argv[1] not in STYLES:
    raise SystemExit('Unknown workspace style')
temporary = STATE.with_suffix('.tmp')
temporary.write_text(json.dumps({'style': sys.argv[1]}) + '\n')
temporary.replace(STATE)
