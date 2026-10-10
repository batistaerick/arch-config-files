#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: apply.sh <theme-name>" >&2
  exit 1
fi

THEMES_DIR="$HOME/.config/themes"
THEME_ROOT="$HOME/.config/theme"
CURRENT_DIR="$THEME_ROOT/current"
THEME_SCRIPTS_DIR="$HOME/.config/walker/scripts/themes"
WALLPAPER_HELPER="$HOME/.config/walker/scripts/actions/wallpaper/transition.py"
LOG_DIR="${XDG_RUNTIME_DIR:-$HOME/.cache}"

# Accept display labels such as "Tokyo Night" as well as folder names.
THEME_NAME="$(
  printf '%s\n' "$1" |
    sed -E 's/<[^>]+>//g' |
    tr '[:upper:]' '[:lower:]' |
    tr ' ' '-'
)"

if [[ ! "$THEME_NAME" =~ ^[a-z0-9-]+$ ]]; then
  notify-send "Theme" "Invalid theme name: $1"
  exit 1
fi

THEME_DIR="$THEMES_DIR/$THEME_NAME"

if [[ ! -d "$THEME_DIR" ]]; then
  notify-send "Theme" "Theme '$THEME_NAME' does not exist"
  exit 1
fi

previous_wallpaper="$(python3 "$WALLPAPER_HELPER" snapshot)"

# Build the new current theme beside the old one, then swap it in so readers
# never observe a half-copied directory.
mkdir -p "$THEME_ROOT"
staging_dir="$(mktemp -d "$THEME_ROOT/.current.XXXXXX")"
trap 'rm -rf -- "$staging_dir" "$THEME_ROOT/.current.old"' EXIT
cp -a "$THEME_DIR"/. "$staging_dir/"
chmod 755 "$staging_dir"

rm -rf -- "$THEME_ROOT/.current.old"
if [[ -e "$CURRENT_DIR" ]]; then
  mv -- "$CURRENT_DIR" "$THEME_ROOT/.current.old"
fi
mv -- "$staging_dir" "$CURRENT_DIR"

mkdir -p "$HOME/.cache"
echo "$THEME_NAME" > "$HOME/.cache/current-theme"

# RGB in background; it logs instead of notifying.
nohup "$THEME_SCRIPTS_DIR/rgb.sh" >"$LOG_DIR/eitr-rgb.log" 2>&1 &

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

mapfile -t wallpapers < <(python3 "$WALLPAPER_HELPER" list "$CURRENT_DIR/backgrounds")
FIRST_WALLPAPER="${wallpapers[0]:-}"

if [[ -n "$FIRST_WALLPAPER" ]]; then
  python3 "$WALLPAPER_HELPER" apply "$FIRST_WALLPAPER" --previous "$previous_wallpaper"
fi

if (( ${#failed_modules[@]} )); then
  notify-send "Theme applied with warnings" "$THEME_NAME: failed modules: ${failed_modules[*]}"
fi
