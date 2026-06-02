#!/usr/bin/env bash

if ! command -v swaync-client >/dev/null 2>&1; then
  notify-send "Notifications" "swaync-client not found"
  exit 1
fi

STATE="$(swaync-client --toggle-dnd | tr -d '\n')"

if [[ "$STATE" == "true" ]]; then
  MESSAGE="󰂛  Notifications muted"
else
  MESSAGE="󰂚  Notifications enabled"
fi

if command -v swayosd-client >/dev/null 2>&1; then
  if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    MONITOR="$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"

    swayosd-client \
      --monitor "$MONITOR" \
      --custom-message "$MESSAGE"
  else
    swayosd-client \
      --custom-message "$MESSAGE"
  fi
else
  notify-send "Notifications" "$MESSAGE"
fi
