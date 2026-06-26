#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
CAPTURE_MENUS_DIR="$MENUS_DIR/capture"

options="󰄀  Screenshot
  Screenrecord
󰈊  Color"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Capture")

case "$chosen" in
  "󰄀  Screenshot")
    "$CAPTURE_MENUS_DIR/screenshot.sh"
    ;;
  "  Screenrecord")
    "$CAPTURE_MENUS_DIR/screenrecord.sh"
    ;;
  "󰈊  Color")
    (sleep 0.2 && hyprpicker -a) &
    ;;
esac
