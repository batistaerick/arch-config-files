#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/themes"

chosen="$(
  find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" |
    sort |
    wofi --dmenu --no-sort --cache-file /dev/null --prompt="Theme"
)"

[ -z "$chosen" ] && exit 0

setsid -f "$HOME/.config/wofi/scripts/actions/apply.sh" "$chosen" >/tmp/apply.log 2>&1 < /dev/null
