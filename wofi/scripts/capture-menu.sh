#!/usr/bin/env bash

options="← Back\n🖼 Screenshot\n  Screenrecord\n󰃉  Color"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Capture")

case "$chosen" in
    "← Back")
        ~/.config/wofi/scripts/trigger-menu.sh
        ;;

    "🖼 Screenshot")
        ~/.config/wofi/scripts/screenshot-menu.sh
        ;;

    "  Screenrecord")
        (sleep 0.2 && obs >/dev/null 2>&1) &
        ;;

    "󰃉  Color")
        (sleep 0.2 && hyprpicker -a) &
        ;;
esac
