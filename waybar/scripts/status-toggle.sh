#!/usr/bin/env bash

set -euo pipefail

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/waybar/status-icons-collapsed"

is_collapsed() {
  local state=""
  [[ -r "$state_file" ]] && state="$(<"$state_file")"
  [[ "$state" == "collapsed" || ( -f "$state_file" && -z "$state" ) ]]
}

print_state() {
  if is_collapsed; then
    printf '{"text":"›","tooltip":"Show status icons","class":["collapsed"]}\n'
  else
    printf '{"text":"‹","tooltip":"Hide status icons","class":["expanded"]}\n'
  fi
}

restart_waybar() {
  setsid -f bash -lc '
    fade="$HOME/.config/waybar/.toggle-fade.css"
    printf "window#waybar { opacity: 0; }\n" > "$fade"
    pkill -USR2 waybar || true
    sleep 0.16
    pkill waybar || true
    systemd-run --user --quiet --collect --unit=waybar-manual-restart "$HOME/.config/waybar/scripts/start-profiled-waybar.sh"
    sleep 0.22
    : > "$fade"
    pkill -USR2 waybar || true
  ' >/dev/null 2>&1
}

case "${1:-state}" in
  state)
    print_state
    ;;
  toggle)
    mkdir -p "$(dirname "$state_file")"
    if is_collapsed; then
      printf 'expanded\n' >"$state_file"
    else
      printf 'collapsed\n' >"$state_file"
    fi
    print_state
    restart_waybar
    ;;
  *)
    echo "Usage: status-toggle.sh [state|toggle]" >&2
    exit 2
    ;;
esac
