#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"
BACKGROUND_DIR="$CURRENT_DIR/backgrounds"

CACHE_IMAGE="$HOME/.cache/current-wallpaper-image"
CACHE_PATH="$HOME/.cache/current-wallpaper"

if [[ ! -d "$BACKGROUND_DIR" ]]; then
  notify-send "Wallpaper" "No backgrounds folder found in current theme"
  exit 1
fi

mapfile -t WALLPAPERS < <(
  find "$BACKGROUND_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) |
    sort -V
)

TOTAL="${#WALLPAPERS[@]}"

if (( TOTAL == 0 )); then
  notify-send "Wallpaper" "No wallpapers found"
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
NEXT_WALLPAPER="${WALLPAPERS[$NEXT_INDEX]}"
NEXT_NAME="$(basename "$NEXT_WALLPAPER")"

ln -sf "$NEXT_WALLPAPER" "$CACHE_IMAGE"
echo "$NEXT_WALLPAPER" > "$CACHE_PATH"

for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
  hyprctl hyprpaper wallpaper "$monitor,$NEXT_WALLPAPER" || true
done
