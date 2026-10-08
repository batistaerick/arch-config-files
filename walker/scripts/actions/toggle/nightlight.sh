#!/usr/bin/env bash

set -euo pipefail

result="$(python3 "$HOME/.config/walker/scripts/actions/toggle/nightlight.py" toggle)"
if [[ "$(jq -r '.enabled' <<< "$result")" == "true" ]]; then
  notify-send -u low "  Nightlight enabled"
else
  notify-send -u low "  Nightlight disabled"
fi
