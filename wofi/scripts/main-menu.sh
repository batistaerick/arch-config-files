#!/usr/bin/env bash

options="󰣇 Apps\n Style\n Update\n󰜉 Trigger\n About\n⏻ Power"

chosen=$(echo -e "$options" | wofi \
  --dmenu \
  --no-sort \
  --cache-file /dev/null \
  --prompt="Menu")

case "$chosen" in
    "󰣇 Apps")
        ~/.config/wofi/scripts/search.sh
        ;;

    " Style")
        ~/.config/wofi/scripts/background-menu.sh
        ;;

    " Update")
        ~/.config/wofi/scripts/update-menu.sh
        ;;

    "󰜉 Trigger")
        ~/.config/wofi/scripts/trigger-menu.sh
        ;;

    " About")
        ~/.config/wofi/scripts/about.sh
        ;;

    "⏻ Power")
        ~/.config/wofi/scripts/power-menu.sh
        ;;

    "")
        exit 0
        ;;

    *)
        encoded_query=$(printf '%s' "$chosen" | jq -sRr @uri)
        xdg-open "https://www.google.com/search?q=$encoded_query"
        ;;
esac
