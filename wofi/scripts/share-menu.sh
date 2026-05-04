#!/usr/bin/env bash

options="← Back\n Clipboard\n File\n Folder"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Share")

case "$chosen" in
    "← Back")
        ~/.config/wofi/scripts/trigger-menu.sh
        ;;

    " Clipboard")
        ~/.config/wofi/scripts/localsend-share.sh clipboard
        ;;

    " File")
        kitty -e ~/.config/wofi/scripts/localsend-share.sh file
        ;;

    " Folder")
        kitty -e ~/.config/wofi/scripts/localsend-share.sh folder
        ;;
esac
