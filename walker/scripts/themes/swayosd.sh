#!/usr/bin/env bash
set -euo pipefail

palette="$HOME/.config/theme/current/colors.toml"
stylesheet="$HOME/.config/swayosd/style.css"
[[ -f "$palette" ]] || exit 0

python3 - "$palette" "$stylesheet" <<'PY'
from pathlib import Path
import sys
import tomllib

with Path(sys.argv[1]).open('rb') as source:
    colors = tomllib.load(source)

background = colors['background']
foreground = colors['foreground']
accent = colors['accent']
style = f'''/* Generated from the active desktop theme. */
@define-color osd_bg {background};
@define-color osd_fg {foreground};
@define-color osd_accent {accent};

window#osd {{
  font-family: "JetBrainsMono Nerd Font";
  border-radius: 6px;
  border: 1px solid alpha(@osd_fg, 0.18);
  background: @osd_bg;
}}
window#osd #container {{ margin: 14px; }}
window#osd image, window#osd label {{ color: @osd_fg; }}
window#osd progressbar:disabled, window#osd image:disabled {{ opacity: 0.5; }}
window#osd progressbar, window#osd segmentedprogress {{
  min-height: 6px;
  border-radius: 3px;
  background: transparent;
  border: none;
}}
window#osd trough, window#osd segment {{
  min-height: inherit;
  border-radius: inherit;
  border: none;
  background: alpha(@osd_fg, 0.16);
}}
window#osd progress, window#osd segment.active {{
  min-height: inherit;
  border-radius: inherit;
  border: none;
  background: @osd_accent;
}}
window#osd segment {{ margin-left: 8px; }}
window#osd segment:first-child {{ margin-left: 0; }}
'''
Path(sys.argv[2]).write_text(style)
PY

if systemctl --user is-active --quiet swayosd-themed.service; then
  systemctl --user restart swayosd-themed.service
elif pgrep -x swayosd-server >/dev/null; then
  pkill -x swayosd-server
  systemd-run --user --unit=swayosd-themed --collect swayosd-server --style "$stylesheet" >/dev/null
fi
