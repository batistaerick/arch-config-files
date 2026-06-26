#!/usr/bin/env bash

set -euo pipefail

wallpaper="${1:-}"

if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
  notify-send "Wallpaper" "Wallpaper file not found"
  exit 1
fi

cache_image="$HOME/.cache/current-wallpaper-image"
cache_path="$HOME/.cache/current-wallpaper"

ln -sf "$wallpaper" "$cache_image"
printf '%s\n' "$wallpaper" > "$cache_path"

for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
  hyprctl hyprpaper wallpaper "$monitor,$wallpaper" || true
done

notify-send "Wallpaper changed" "$(basename "$wallpaper")"
