#!/usr/bin/env bash

set -e

if [[ -z "$1" ]]; then
  echo "Usage: theme-apply.sh <theme-name>"
  exit 1
fi

THEMES_DIR="$HOME/.config/themes"
CURRENT_DIR="$HOME/.config/theme/current"
THEME_NAME="$(echo "$1" | sed -E 's/<[^>]+>//g' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
THEME_DIR="$THEMES_DIR/$THEME_NAME"

if [[ ! -d "$THEME_DIR" ]]; then
  notify-send "Theme" "Theme '$THEME_NAME' does not exist"
  exit 1
fi

rm -rf "$CURRENT_DIR"
mkdir -p "$CURRENT_DIR"

cp -r "$THEME_DIR/"* "$CURRENT_DIR/" 2>/dev/null || true

mkdir -p "$HOME/.cache"
echo "$THEME_NAME" > "$HOME/.cache/current-theme"

GTK_ENV_FILE="$HOME/.config/hypr/theme-env.conf"

nohup ~/.config/wofi/scripts/themes/rgb.sh >/tmp/rgb.log 2>&1 &

~/.config/wofi/scripts/themes/sddm.sh
~/.config/wofi/scripts/themes/system.sh
~/.config/wofi/scripts/themes/wofi.sh
~/.config/wofi/scripts/themes/kitty.sh
~/.config/wofi/scripts/themes/vscode.sh
~/.config/wofi/scripts/themes/intellij.sh
~/.config/wofi/scripts/themes/swaync.sh

if [[ -f "$CURRENT_DIR/hyprland.conf" ]]; then
  mkdir -p "$HOME/.config/hypr/themes"
  cp "$CURRENT_DIR/hyprland.conf" "$HOME/.config/hypr/themes/current.conf"
  hyprctl reload
fi

if pgrep -x nautilus >/dev/null; then
  nautilus -q 2>/dev/null
fi

if [[ -f "$CURRENT_DIR/wofi.css" ]]; then
  mkdir -p "$HOME/.config/wofi/themes"
  cp "$CURRENT_DIR/wofi.css" "$HOME/.config/wofi/themes/current.css"
fi

FIRST_WALLPAPER="$(
  find "$CURRENT_DIR/backgrounds" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null |
    sort |
    head -n 1
)"

if [[ -n "$FIRST_WALLPAPER" ]]; then
  ln -sf "$FIRST_WALLPAPER" "$HOME/.cache/current-wallpaper-image"
  echo "$FIRST_WALLPAPER" > "$HOME/.cache/current-wallpaper"

  for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
    hyprctl hyprpaper wallpaper "$monitor,$FIRST_WALLPAPER" || true
  done
fi

notify-send "Theme applied" "$THEME_NAME"
