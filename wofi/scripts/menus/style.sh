#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"

options="←  Back\n󰸌  Theme\n🖻  Wallpaper"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Style")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "󰸌  Theme")
    "$MENUS_DIR/theme.sh"
    ;;
  "🖻  Wallpaper")
    "$MENUS_DIR/wallpaper.sh"
    ;;
esac
