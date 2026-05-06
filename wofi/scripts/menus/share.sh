#!/usr/bin/env bash

options="←  Back\n  Clipboard\n  File\n  Folder"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Share")

case "$chosen" in
  "←  Back")
    ~/.config/wofi/scripts/menus/main.sh
    ;;
  "  Clipboard")
    ~/.config/wofi/scripts/actions/localsend-share.sh clipboard
    ;;
  "  File")
    kitty -e ~/.config/wofi/scripts/actions/localsend-share.sh file
    ;;
  "  Folder")
    kitty -e ~/.config/wofi/scripts/actions/localsend-share.sh folder
    ;;
esac
