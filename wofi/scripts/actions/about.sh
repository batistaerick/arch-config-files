#!/usr/bin/env bash

set -euo pipefail

CLASS="about-terminal"
WORKSPACE="setup"

if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  if clients_json="$(hyprctl clients -j 2>/dev/null)"; then
    if printf '%s\n' "$clients_json" | jq -e --arg class "$CLASS" '.[] | select(.class == $class)' >/dev/null; then
      hyprctl dispatch togglespecialworkspace "$WORKSPACE" >/dev/null
      exit 0
    fi

    hyprctl dispatch exec "[workspace special:$WORKSPACE silent] kitty --class $CLASS --title About -e bash -lc 'fastfetch; echo; read -n 1 -s -r -p \"\"'" >/dev/null
    sleep 0.3
    hyprctl dispatch togglespecialworkspace "$WORKSPACE" >/dev/null
    exit 0
  fi
fi

kitty --class "$CLASS" --title "About" -e bash -lc 'fastfetch; echo; read -n 1 -s -r -p ""'
