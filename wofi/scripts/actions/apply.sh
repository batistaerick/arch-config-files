#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: theme-apply.sh <theme-name>"
  exit 1
fi

THEMES_DIR="$HOME/.config/themes"
CURRENT_DIR="$HOME/.config/theme/current"
HYPR_THEMES_DIR="$HOME/.config/hypr/themes"
WOFI_THEMES_DIR="$HOME/.config/wofi/themes"
WOFI_THEME_SCRIPTS_DIR="$HOME/.config/wofi/scripts/themes"

THEME_NAME="$(
  echo "$1" |
    sed -E 's/<[^>]+>//g' |
    tr '[:upper:]' '[:lower:]' |
    tr ' ' '-'
)"

THEME_DIR="$THEMES_DIR/$THEME_NAME"

if [[ ! -d "$THEME_DIR" ]]; then
  notify-send "Theme" "Theme '$THEME_NAME' does not exist"
  exit 1
fi

rm -rf "$CURRENT_DIR"
mkdir -p "$CURRENT_DIR"

# Copy all theme files, including hidden files
cp -a "$THEME_DIR"/. "$CURRENT_DIR/"

mkdir -p "$HOME/.cache"
echo "$THEME_NAME" > "$HOME/.cache/current-theme"

# RGB in background
nohup "$WOFI_THEME_SCRIPTS_DIR/rgb.sh" >/tmp/rgb.log 2>&1 &

# Apply theme modules
"$WOFI_THEME_SCRIPTS_DIR/sddm.sh"
"$WOFI_THEME_SCRIPTS_DIR/system.sh"
"$WOFI_THEME_SCRIPTS_DIR/wofi.sh"
"$WOFI_THEME_SCRIPTS_DIR/kitty.sh"
"$WOFI_THEME_SCRIPTS_DIR/vscode.sh"
"$WOFI_THEME_SCRIPTS_DIR/intellij.sh"
"$WOFI_THEME_SCRIPTS_DIR/swaync.sh"

# Hyprland theme files
mkdir -p "$HYPR_THEMES_DIR"

if [[ -f "$CURRENT_DIR/hyprland.conf" ]]; then
  cp "$CURRENT_DIR/hyprland.conf" "$HYPR_THEMES_DIR/current.conf"
fi

if [[ -f "$CURRENT_DIR/hyprland.lua" ]]; then
  cp "$CURRENT_DIR/hyprland.lua" "$HYPR_THEMES_DIR/current.lua"
fi

# Theme env file used by hyprland.lua load_theme_env()
if [[ -f "$CURRENT_DIR/theme-env.conf" ]]; then
  cp "$CURRENT_DIR/theme-env.conf" "$HOME/.config/hypr/theme-env.conf"
fi

# Wofi theme
if [[ -f "$CURRENT_DIR/wofi.css" ]]; then
  mkdir -p "$WOFI_THEMES_DIR"
  cp "$CURRENT_DIR/wofi.css" "$WOFI_THEMES_DIR/current.css"
fi

# Reload Hyprland after theme/env files are copied
hyprctl reload || true

# Restart file managers so they inherit new theme/env
if pgrep -x nautilus >/dev/null; then
  nautilus -q 2>/dev/null || true
fi

if pgrep -x dolphin >/dev/null; then
  kquitapp6 dolphin 2>/dev/null || pkill dolphin || true
fi

# Rebuild KDE service cache for Dolphin/KDE apps
if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 >/dev/null 2>&1 || true
fi

# Wallpaper
FIRST_WALLPAPER="$(
  find "$CURRENT_DIR/backgrounds" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null |
    sort |
    head -n 1
)"

if [[ -n "$FIRST_WALLPAPER" ]]; then
  ln -sf "$FIRST_WALLPAPER" "$HOME/.cache/current-wallpaper-image"
  echo "$FIRST_WALLPAPER" > "$HOME/.cache/current-wallpaper"

  while read -r monitor; do
    hyprctl hyprpaper wallpaper "$monitor,$FIRST_WALLPAPER" || true
  done < <(hyprctl monitors -j | jq -r '.[].name')
fi

notify-send "Theme applied" "$THEME_NAME"
