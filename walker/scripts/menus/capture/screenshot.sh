#!/usr/bin/env bash

DIR="$HOME/Pictures/Screenshots"
MENUS_DIR="$HOME/.config/walker/scripts/menus"
ACTIONS_DIR="$HOME/.config/walker/scripts/actions"
CAPTURE_ACTIONS_DIR="$ACTIONS_DIR/capture"
mkdir -p "$DIR"

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

options="󰆞  Selection
󰹑  Full Screen"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Screenshot")

sleep 0.2

case "$chosen" in
  "󰆞  Selection")
    "$CAPTURE_ACTIONS_DIR/screenshot-selection.sh"
    notify-send "Screenshot saved" "$FILE"
    ;;
  "󰹑  Full Screen")
    "$CAPTURE_ACTIONS_DIR/screenshot-full.sh"
    notify-send "Screenshot saved" "$FILE"
    ;;
esac
