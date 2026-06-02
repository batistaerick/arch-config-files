#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"
BACKGROUND_DIR="$CURRENT_DIR/backgrounds"

CACHE_IMAGE="$HOME/.cache/current-wallpaper-image"
CACHE_PATH="$HOME/.cache/current-wallpaper"

if [[ ! -d "$BACKGROUND_DIR" ]]; then
  notify-send "Wallpaper" "No backgrounds folder found in current theme"
  exit 1
fi

chosen="$(
  find "$BACKGROUND_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    -printf "%f\n" |
    sort -V |
    wofi --dmenu --no-sort --cache-file /dev/null --prompt="Wallpaper"
)"

[[ -z "$chosen" ]] && exit 0

WALLPAPER="$BACKGROUND_DIR/$chosen"

# Preview selected wallpaper
imv "$WALLPAPER" &
preview_pid=$!

confirm="$(
  printf "Apply\nCancel\n" |
    wofi --dmenu --no-sort --cache-file /dev/null --prompt="Apply this wallpaper?"
)"

kill "$preview_pid" 2>/dev/null

[[ "$confirm" != "Apply" ]] && exit 0

# Keep last wallpaper persistent for hyprpaper.conf
ln -sf "$WALLPAPER" "$CACHE_IMAGE"
echo "$WALLPAPER" > "$CACHE_PATH"

# Apply live to all monitors
for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
  hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER" || true
done

notify-send "Wallpaper changed" "$chosen"
