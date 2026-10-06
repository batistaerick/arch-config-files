#!/usr/bin/env python3
import json
from pathlib import Path
import sys

STYLES = ('Numbers', 'Glyph', 'Dots')
STATE = Path.home() / '.config/quickshell/desktop-bar/workspace-style.json'

if len(sys.argv) == 2 and sys.argv[1] == 'current':
    try:
        style = json.loads(STATE.read_text()).get('style', 'Numbers')
    except (OSError, ValueError, AttributeError):
        style = 'Numbers'
    if style == 'Aurora':
        style = 'Dots'
    print(style if style in STYLES else 'Numbers')
    raise SystemExit(0)

if len(sys.argv) != 2 or sys.argv[1] not in STYLES:
    raise SystemExit('Unknown workspace style')
temporary = STATE.with_suffix('.tmp')
temporary.write_text(json.dumps({'style': sys.argv[1]}) + '\n')
temporary.replace(STATE)
