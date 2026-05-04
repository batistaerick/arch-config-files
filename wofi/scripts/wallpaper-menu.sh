#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"
BACKGROUND_DIR="$CURRENT_DIR/backgrounds"

if [[ ! -d "$BACKGROUND_DIR" ]]; then
  notify-send "Wallpaper" "No backgrounds folder found in current theme"
  exit 1
fi

chosen="$(
  find "$BACKGROUND_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    -printf "%f\n" |
    sort |
    wofi --dmenu --no-sort --cache-file /dev/null --prompt="Wallpaper"
)"

[[ -z "$chosen" ]] && exit 0

WALLPAPER="$BACKGROUND_DIR/$chosen"

# Keep last wallpaper persistent for hyprpaper.conf
ln -sf "$WALLPAPER" "$HOME/.cache/current-wallpaper-image"
echo "$WALLPAPER" > "$HOME/.cache/current-wallpaper"

# Apply live to all monitors
for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
  hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER" || true
done

notify-send "Wallpaper changed" "$chosen"
