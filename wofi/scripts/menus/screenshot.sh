#!/usr/bin/env bash

DIR="$HOME/Pictures/Screenshots"
MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"
mkdir -p "$DIR"

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

options="←  Back
󰆞  Selection
󰹑  Full Screen"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Screenshot")

sleep 0.2

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/capture.sh"
    ;;
  "󰆞  Selection")
    "$ACTIONS_DIR/screenshot-selection.sh"
    notify-send "Screenshot saved" "$FILE"
    ;;
  "󰹑  Full Screen")
    "$ACTIONS_DIR/screenshot-full.sh"
    notify-send "Screenshot saved" "$FILE"
    ;;
esac
