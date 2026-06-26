#!/usr/bin/env bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"
MONITOR="$(hyprctl monitors -j | jq -r '.[] | select(.focused==true).name')"

grim -o "$MONITOR" - | satty \
  -f - \
  -o "$FILE" \
  --copy-command "wl-copy" \
  --early-exit
