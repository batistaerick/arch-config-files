#!/usr/bin/env bash

set -euo pipefail

class="${1:-}"
shift || true

if [[ -z "$class" || "$#" -eq 0 ]]; then
  echo "Usage: toggle-setup-window.sh <class> <command> [args...]" >&2
  exit 2
fi

lua_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

if hyprctl clients -j | jq -e --arg class "$class" '.[] | select(.class == $class)' >/dev/null; then
  hyprctl dispatch 'hl.dsp.workspace.toggle_special("setup")'
else
  command_string="$(printf '%q ' "$@")"
  command_string="[workspace special:setup silent] ${command_string% }"
  hyprctl dispatch "hl.dsp.exec_cmd(\"$(lua_escape "$command_string")\")"
  sleep 0.3
  hyprctl dispatch 'hl.dsp.workspace.toggle_special("setup")'
fi
