#!/usr/bin/env bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

options="← Back\n Selection\n Full Screen"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Screenshot")

case "$chosen" in
    "← Back")
        ~/.config/wofi/scripts/capture-menu.sh
        ;;

    " Selection")
        grim -g "$(slurp)" - | satty -f - -o "$FILE" --early-exit
        notify-send "Screenshot saved" "$FILE"
        ;;

    " Focused Screen")
        MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true).name')
        grim -o "$MONITOR" - | satty -f - -o "$FILE" --early-exit
        notify-send "Screenshot saved" "$FILE"
        ;;
esac
