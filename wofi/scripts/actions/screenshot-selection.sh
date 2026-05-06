#!/usr/bin/env bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

GEOMETRY="$(slurp)" || exit 0

grim -g "$GEOMETRY" - | satty \
  -f - \
  -o "$FILE" \
  --copy-command "wl-copy" \
  --early-exit
