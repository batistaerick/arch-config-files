#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
STYLE_MENUS_DIR="$MENUS_DIR/style"

options="←  Back
󰸌  Theme
🖻  Wallpaper"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Style")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "󰸌  Theme")
    "$STYLE_MENUS_DIR/theme.sh"
    ;;
  "🖻  Wallpaper")
    "$STYLE_MENUS_DIR/wallpaper.sh"
    ;;
esac
