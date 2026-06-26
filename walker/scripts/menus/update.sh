#!/usr/bin/env bash

options="󰚰  Pacman (official packages)
󰀦  Yay (AUR + pacman)
󰜉  Full upgrade (clean)"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Update")

case "$chosen" in
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
