#!/usr/bin/env bash

options="← Back\n Shutdown\n Reboot\n Suspend\n Logout"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null)

case $chosen in
    "← Back")
        ~/.config/wofi/scripts/main-menu.sh
        ;;

    " Shutdown")
        systemctl poweroff
        ;;
    " Reboot")
        systemctl reboot
        ;;
    " Suspend")
        systemctl suspend
        ;;
    " Logout")
        hyprctl dispatch exit
        ;;
esac
