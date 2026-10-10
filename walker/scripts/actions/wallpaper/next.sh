#!/usr/bin/env bash

set -euo pipefail

WALLPAPER_DIR="$HOME/.config/walker/scripts/actions/wallpaper"
BACKGROUND_DIR="$HOME/.config/theme/current/backgrounds"
CACHE_PATH="$HOME/.cache/current-wallpaper"

mapfile -t WALLPAPERS < <(python3 "$WALLPAPER_DIR/transition.py" list "$BACKGROUND_DIR")

TOTAL="${#WALLPAPERS[@]}"

if (( TOTAL == 0 )); then
  notify-send "Wallpaper" "No wallpapers found in the current theme"
  exit 1
fi

CURRENT_WALLPAPER=""

if [[ -f "$CACHE_PATH" ]]; then
  CURRENT_WALLPAPER="$(cat "$CACHE_PATH")"
fi

CURRENT_INDEX=-1

for i in "${!WALLPAPERS[@]}"; do
  if [[ "${WALLPAPERS[$i]}" == "$CURRENT_WALLPAPER" ]]; then
    CURRENT_INDEX="$i"
    break
  fi
done

NEXT_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL ))

exec bash "$HOME/.config/walker/scripts/actions/wallpaper/apply.sh" "${WALLPAPERS[$NEXT_INDEX]}"
