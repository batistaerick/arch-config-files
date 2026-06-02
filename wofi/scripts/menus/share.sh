#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
SHARE_ACTIONS_DIR="$HOME/.config/wofi/scripts/actions/share"

options="←  Back
  Clipboard
  File
  Folder"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Share")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "  Clipboard")
    "$SHARE_ACTIONS_DIR/localsend-share.sh" clipboard
    ;;
  "  File")
    kitty -e "$SHARE_ACTIONS_DIR/localsend-share.sh" file
    ;;
  "  Folder")
    kitty -e "$SHARE_ACTIONS_DIR/localsend-share.sh" folder
    ;;
esac
