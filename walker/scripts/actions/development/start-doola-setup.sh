#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.nvm/versions/node/v24.15.0/bin:$HOME/.sdkman/candidates/java/current/bin:$PATH"

DOOLA_DIR="$HOME/Development/doola"
DOOLA_DATA_DIR="$DOOLA_DIR/doola-data"
CHROME_PROFILE="Profile 1"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

lua_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

hypr_exec() {
  local command="$1"
  if $DRY_RUN; then
    printf '%s\n' "$command"
    return
  fi

  hyprctl dispatch "hl.dsp.exec_cmd(\"$(lua_escape "$command")\")" >/dev/null
}

hdmi_connected() {
  for status in /sys/class/drm/card*-HDMI-A-1/status; do
    [[ -e "$status" ]] || continue
    grep -qx connected "$status" && return 0
  done

  return 1
}

require_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    notify-send "Doola Setup" "$path does not exist"
    exit 1
  fi
}

require_command() {
  local command="$1"
  if ! command -v "$command" >/dev/null 2>&1; then
    notify-send "Doola Setup" "$command is not installed"
    exit 1
  fi
}

require_dir "$DOOLA_DIR"
require_dir "$DOOLA_DATA_DIR"

for command in kitty claude nvim postman dbeaver google-chrome-stable slack hyprctl; do
  require_command "$command"
done

CLAUDE_BIN="$(command -v claude)"

browser_workspace="3"
if hdmi_connected; then
  browser_workspace="4"
fi

hypr_exec "[workspace 1 silent] kitty --class doola-claude --directory '$DOOLA_DIR' zsh -ic '$CLAUDE_BIN -r; exec zsh'"
hypr_exec "[workspace 1 silent] kitty --class doola-nvim --directory '$DOOLA_DATA_DIR' -e nvim ."

hypr_exec "[workspace 2 silent] postman"
hypr_exec "[workspace 2 silent] dbeaver"

hypr_exec "[workspace $browser_workspace silent] google-chrome-stable --profile-directory='$CHROME_PROFILE' --new-window"
hypr_exec "[workspace $browser_workspace silent] slack"

$DRY_RUN && exit 0

hyprctl dispatch "hl.dsp.focus({ workspace = 1 })" >/dev/null
notify-send "Doola Setup" "Started workspace layout"
