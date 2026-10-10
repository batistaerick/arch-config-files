#!/usr/bin/env bash

set -euo pipefail

wallpaper="${1:-}"

if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
  notify-send "Wallpaper" "Wallpaper file not found"
  exit 1
fi

exec python3 "$HOME/.config/walker/scripts/actions/wallpaper/transition.py" apply "$wallpaper"
