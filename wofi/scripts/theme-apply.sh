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

# GNOME / GTK / Libadwaita color mode
GTK_ENV_FILE="$HOME/.config/hypr/theme-env.conf"

# GNOME / GTK / Libadwaita color mode
~/.config/wofi/scripts/apply-gnome-theme.sh

# Kitty
~/.config/wofi/scripts/apply-kitty-theme.sh

# VS Code
~/.config/wofi/scripts/apply-vscode-theme.sh

# Optional: Hyprland theme, only if the theme provides hyprland.conf
if [[ -f "$CURRENT_DIR/hyprland.conf" ]]; then
  mkdir -p "$HOME/.config/hypr/themes"
  cp "$CURRENT_DIR/hyprland.conf" "$HOME/.config/hypr/themes/current.conf"
  hyprctl reload
fi

if pgrep -x nautilus >/dev/null; then
  nautilus -q 2>/dev/null
fi

# Optional: Wofi theme, only if the theme provides wofi.css
if [[ -f "$CURRENT_DIR/wofi.css" ]]; then
  mkdir -p "$HOME/.config/wofi/themes"
  cp "$CURRENT_DIR/wofi.css" "$HOME/.config/wofi/themes/current.css"
fi

# Set first wallpaper from selected theme
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
