#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
STYLE_MENUS_DIR="$MENUS_DIR/style"

options="󰸌  Theme
🖻  Wallpaper"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Style")

case "$chosen" in
  "󰸌  Theme")
    "$STYLE_MENUS_DIR/theme.sh"
    ;;
  "🖻  Wallpaper")
    "$STYLE_MENUS_DIR/wallpaper.sh"
    ;;
esac
