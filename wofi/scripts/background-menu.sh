#!/usr/bin/env bash

options="← Back\n󰸌 Theme\n🖼 Wallpaper"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Background")

case "$chosen" in
    "← Back")
        ~/.config/wofi/scripts/main-menu.sh
        ;;

    "󰸌 Theme")
        ~/.config/wofi/scripts/theme-menu.sh
        ;;

    "🖼 Wallpaper")
        ~/.config/wofi/scripts/wallpaper-menu.sh
        ;;
esac
