#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
ACTIONS_DIR="$HOME/.config/walker/scripts/actions"
HYPR_SCRIPTS_DIR="$HOME/.config/hypr/scripts"

options="  Shutdown
  Reboot
  Lock
  Suspend
  Logout
  Reboot BIOS"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Power")

case $chosen in
  "  Shutdown")
    systemctl poweroff
    ;;
  "  Reboot")
    systemctl reboot
    ;;
  "  Lock")
    "$HYPR_SCRIPTS_DIR/manual-lock.sh"
    ;;
  "  Suspend")
    loginctl lock-session && sleep 1 && systemctl suspend
    ;;
  "  Logout")
    uwsm stop
    ;;
  "  Reboot BIOS")
    kitty -e systemctl reboot --firmware-setup
    ;;
esac
