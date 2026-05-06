#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"
KITTY_THEME="$HOME/.config/kitty/theme.conf"

if [[ ! -f "$CURRENT_DIR/colors.toml" ]]; then
  exit 0
fi

mkdir -p "$HOME/.config/kitty"

python - "$CURRENT_DIR/colors.toml" "$KITTY_THEME" <<'PY'
import sys
import tomllib
from pathlib import Path

colors_path = Path(sys.argv[1])
kitty_path = Path(sys.argv[2])

data = tomllib.loads(colors_path.read_text())

def get(*keys, default=None):
    cur = data
    for key in keys:
        if not isinstance(cur, dict) or key not in cur:
            return default
        cur = cur[key]
    return cur

# Support simple Omarchy-style colors.toml.
# If your colors.toml structure is different, send me one file and I adapt this.
bg = get("colors", "background") or get("background") or "#1e1e2e"
fg = get("colors", "foreground") or get("foreground") or "#cdd6f4"
cursor = get("colors", "cursor") or get("cursor") or fg
selection_bg = get("colors", "selection_background") or get("selection_background") or "#45475a"
selection_fg = get("colors", "selection_foreground") or get("selection_foreground") or fg

black = get("colors", "black") or get("black") or "#45475a"
red = get("colors", "red") or get("red") or "#f38ba8"
green = get("colors", "green") or get("green") or "#a6e3a1"
yellow = get("colors", "yellow") or get("yellow") or "#f9e2af"
blue = get("colors", "blue") or get("blue") or "#89b4fa"
magenta = get("colors", "magenta") or get("magenta") or "#cba6f7"
cyan = get("colors", "cyan") or get("cyan") or "#94e2d5"
white = get("colors", "white") or get("white") or "#bac2de"

bright_black = get("colors", "bright_black") or get("bright_black") or "#585b70"
bright_red = get("colors", "bright_red") or get("bright_red") or red
bright_green = get("colors", "bright_green") or get("bright_green") or green
bright_yellow = get("colors", "bright_yellow") or get("bright_yellow") or yellow
bright_blue = get("colors", "bright_blue") or get("bright_blue") or blue
bright_magenta = get("colors", "bright_magenta") or get("bright_magenta") or magenta
bright_cyan = get("colors", "bright_cyan") or get("bright_cyan") or cyan
bright_white = get("colors", "bright_white") or get("bright_white") or "#a6adc8"

kitty = f"""# Auto-generated from ~/.config/theme/current/colors.toml

background {bg}
foreground {fg}

cursor {cursor}
cursor_text_color {bg}

selection_background {selection_bg}
selection_foreground {selection_fg}

color0 {black}
color1 {red}
color2 {green}
color3 {yellow}
color4 {blue}
color5 {magenta}
color6 {cyan}
color7 {white}

color8 {bright_black}
color9 {bright_red}
color10 {bright_green}
color11 {bright_yellow}
color12 {bright_blue}
color13 {bright_magenta}
color14 {bright_cyan}
color15 {bright_white}
"""

kitty_path.write_text(kitty)
PY

kitty @ set-colors --all --configured "$KITTY_THEME" >/dev/null 2>&1 || true
