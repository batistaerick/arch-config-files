#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"

options="←  Back\n🖼 Screenshot\n  Screenrecord\n󰃉  Color"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Capture")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "🖼 Screenshot")
    "$MENUS_DIR/screenshot.sh"
    ;;
  "  Screenrecord")
    (sleep 0.2 && obs >/dev/null 2>&1) &
    ;;
  "󰃉  Color")
    (sleep 0.2 && hyprpicker -a) &
    ;;
esac
