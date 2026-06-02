#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
GCP_MENUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEFAULT_TIME_RANGE_MINUTES="30"

wofi_menu() {
  local prompt="$1"
  shift

  if [ "$#" -gt 0 ]; then
    printf "%s\n" "$@"
  else
    cat
  fi | wofi \
      --dmenu \
      --no-sort \
      --matching=contains \
      --cache-file /dev/null \
      --prompt "$prompt"
}

choose_time_range_minutes() {
  local value

  value=$(wofi_menu "Minutes" "15" "30" "60" "120" "360" "1440")

  if [ -z "$value" ] || ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "$DEFAULT_TIME_RANGE_MINUTES"
    return
  fi

  echo "$value"
}

gcp_cli_available() {
  command -v gcloud >/dev/null 2>&1
}

require_gcloud() {
  if ! gcp_cli_available; then
    notify-send "GCP" "gcloud CLI is not installed"
    exit 0
  fi
}

choose_gcp_project() {
  local projects
  local chosen

  require_gcloud

  if ! projects="$(gcloud projects list --format='value(projectId)' 2>/dev/null)"; then
    notify-send "GCP" "Failed to list projects. Login or configure gcloud first."
    exit 1
  fi

  if [ -z "$projects" ]; then
    notify-send "GCP" "No projects found"
    exit 0
  fi

  chosen="$(printf "%s\n" "$projects" | wofi_menu "GCP Project")"
  [ -z "$chosen" ] && exit 0

  echo "$chosen"
}

back_to_gcp_menu() {
  "$GCP_MENUS_DIR/menu.sh"
}

cloud_terminal_helpers() {
  cat <<'EOF'
cloud_reset=$'\033[0m'
cloud_bold=$'\033[1m'
cloud_red=$'\033[31m'
cloud_green=$'\033[32m'
cloud_yellow=$'\033[33m'
cloud_blue=$'\033[34m'
cloud_cyan=$'\033[36m'
cloud_dim=$'\033[2m'

cloud_header() {
  printf '\n%s%s%s\n' "$cloud_bold$cloud_cyan" "$1" "$cloud_reset"
  printf '%s\n' "${cloud_dim}────────────────────────────────────────${cloud_reset}"
}

cloud_kv() {
  printf '%s%-12s%s %s\n' "$cloud_blue" "$1:" "$cloud_reset" "$2"
}

cloud_success() {
  printf '%s%s%s\n' "$cloud_green" "$1" "$cloud_reset"
}

cloud_warn() {
  printf '%s%s%s\n' "$cloud_yellow" "$1" "$cloud_reset"
}

cloud_fzf() {
  local prompt="${1:-Filter}"
  local output
  local status
  local key

  if command -v fzf >/dev/null 2>&1; then
    output="$(fzf \
      --ansi \
      --no-sort \
      --cycle \
      --height=100% \
      --layout=reverse \
      --border \
      --color='fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8,info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc,marker:#a6e3a1,spinner:#f9e2af,header:#94e2d5,border:#89b4fa' \
      --prompt="$prompt > " \
      --header="Type to filter. Enter prints selection. Esc closes." \
      --preview='printf "%b\n" {} | bat --style=plain --color=always --language=log 2>/dev/null || printf "%b\n" {}' \
      --preview-window='down,35%,wrap' \
      --expect=ctrl-c,esc)"
    status=$?

    if [ "$status" -ne 0 ]; then
      [ "$status" -eq 130 ] && return 130
      return 0
    fi

    key="${output%%$'\n'*}"
    [ "$key" = "ctrl-c" ] && return 130
    [ "$key" = "esc" ] && return 0

    printf '%s\n' "$output"
  else
    cat
  fi
}
EOF
}

run_in_kitty() {
  local title="$1"
  local command="$2"
  local close_mode="${3:-keep-open}"
  local temp_script

  temp_script="$(mktemp /tmp/gcp-ops.XXXXXX.sh)"

  cat > "$temp_script" <<EOF
#!/usr/bin/env bash

set -o pipefail

clear

$(cloud_terminal_helpers)

trap 'exit 130' INT

$command

status=\$?

if [ "\$status" -eq 130 ]; then
  exit 130
fi

if [ "\$status" -eq 0 ] && [ "$close_mode" = "close-on-success" ]; then
  exit 0
fi

echo
echo "────────────────────────────────────────"
echo "Exit code: \$status"
echo "Terminal will stay open."
echo "You can run more commands here manually."
echo "────────────────────────────────────────"
echo

exec "\${SHELL:-/bin/bash}" -l
EOF

  chmod +x "$temp_script"
  kitty --title "$title" "$temp_script"
}
