#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
SHARE_ACTIONS_DIR="$HOME/.config/walker/scripts/actions/share"

options="  Clipboard
  File
  Folder"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Share")

case "$chosen" in
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
