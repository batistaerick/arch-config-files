#!/usr/bin/env bash

options="←  Back
󰚰  Pacman (official packages)
󰀦  Yay (AUR + pacman)
󰜉  Full upgrade (clean)"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Update")

case "$chosen" in
  "←  Back")
    ~/.config/wofi/scripts/menus/main.sh
    ;;
  "󰚰  Pacman (official packages)")
    kitty -e sudo pacman -Syu
    ;;
  "󰀦  Yay (AUR + pacman)")
    kitty -e yay -Syu
    ;;
  "󰜉  Full upgrade (clean)")
    kitty -e bash -c "sudo pacman -Syu && yay -Sua --devel"
    ;;
esac
