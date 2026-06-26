#!/usr/bin/env bash

set -euo pipefail

CLASS="about-terminal"
ABOUT_COMMAND='fastfetch; echo; read -n 1 -s -r -p ""'

if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  if clients_json="$(hyprctl clients -j 2>/dev/null)"; then
    if printf '%s\n' "$clients_json" | jq -e --arg class "$CLASS" '.[] | select(.class == $class)' >/dev/null; then
      hyprctl dispatch focuswindow "class:$CLASS" >/dev/null
      exit 0
    fi
  fi
fi

setsid -f kitty --class "$CLASS" --title "About" -e bash -lc "$ABOUT_COMMAND" >/tmp/about-terminal.log 2>&1 < /dev/null
