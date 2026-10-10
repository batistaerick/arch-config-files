#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: theme-apply.sh <theme-name>"
  exit 1
fi

THEMES_DIR="$HOME/.config/themes"
CURRENT_DIR="$HOME/.config/theme/current"
HYPR_THEMES_DIR="$HOME/.config/hypr/themes"
THEME_SCRIPTS_DIR="$HOME/.config/walker/scripts/themes"

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

previous_wallpaper="$(python3 "$HOME/.config/walker/scripts/actions/wallpaper/transition.py" snapshot)"
rm -rf "$CURRENT_DIR"
mkdir -p "$CURRENT_DIR"

# Copy all theme files, including hidden files
cp -a "$THEME_DIR"/. "$CURRENT_DIR/"

mkdir -p "$HOME/.cache"
echo "$THEME_NAME" > "$HOME/.cache/current-theme"

# RGB in background
nohup "$THEME_SCRIPTS_DIR/rgb.sh" >/tmp/rgb.log 2>&1 &

# Apply theme modules
failed_modules=()
for module in system walker btop kitty vscode swayosd; do
  if ! "$THEME_SCRIPTS_DIR/$module.sh"; then
    failed_modules+=("$module")
    printf 'Theme module failed: %s\n' "$module" >&2
  fi
done

# hyprland.lua reads the active palette for borders and other colors.
hyprctl reload || true

# Kvantum and KDE color schemes are read when a Qt app starts, so a running
# Dolphin keeps the previous theme until it is restarted.
if pgrep -x dolphin >/dev/null; then
  kquitapp6 dolphin 2>/dev/null || pkill -x dolphin || true
fi

# Rebuild KDE service cache for Dolphin/KDE apps
if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 >/dev/null 2>&1 || true
fi

# Wallpaper
mapfile -t wallpapers < <(
  find "$CURRENT_DIR/backgrounds" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null |
    sort
)
FIRST_WALLPAPER="${wallpapers[0]:-}"

if [[ -n "$FIRST_WALLPAPER" ]]; then
  python3 "$HOME/.config/walker/scripts/actions/wallpaper/transition.py" apply "$FIRST_WALLPAPER" --previous "$previous_wallpaper"
fi

if (( ${#failed_modules[@]} )); then
  notify-send "Theme applied with warnings" "$THEME_NAME: failed modules: ${failed_modules[*]}"
fi
