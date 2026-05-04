#!/usr/bin/env bash

options="← Back\n Capture\n Share"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Trigger")

case "$chosen" in
    "← Back")
        ~/.config/wofi/scripts/main-menu.sh
        ;;

    " Capture")
        ~/.config/wofi/scripts/capture-menu.sh
        ;;

    " Share")
        ~/.config/wofi/scripts/share-menu.sh
        ;;
esac
