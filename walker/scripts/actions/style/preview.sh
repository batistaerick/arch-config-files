#!/usr/bin/env bash
set -euo pipefail

theme="${1:-}"
[[ -n "$theme" && "$theme" != */* && "$theme" != . && "$theme" != .. ]] || exit 1
image="$HOME/.config/themes/$theme/preview.png"
sleep 0.2
if [[ -f "$image" ]]; then
    imv -f -s full -c 'bind <Escape> quit' -w "Theme preview: $theme" "$image" || true
else
    notify-send "Theme preview" "No preview image found for $theme"
fi
exec walker --provider menus:theme
