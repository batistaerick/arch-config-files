#!/usr/bin/env bash

options="󰚰  Pacman (official packages)
󰀦  Yay (AUR + pacman)
󰜉  Full upgrade (clean)"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Update")

case "$chosen" in
  "󰚰  Pacman (official packages)")
    kitty --hold -e bash "$HOME/.config/walker/scripts/actions/system/update.sh" pacman
    ;;
  "󰀦  Yay (AUR + pacman)")
    kitty --hold -e bash "$HOME/.config/walker/scripts/actions/system/update.sh" yay
    ;;
  "󰜉  Full upgrade (clean)")
    kitty --hold -e bash "$HOME/.config/walker/scripts/actions/system/update.sh" full
    ;;
esac
