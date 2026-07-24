#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
AZURE_MENUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

  value=$(wofi_menu "Minutes" "←  Back" "15" "30" "60" "120" "360" "1440")

  if [ "$value" = "←  Back" ]; then
    echo "__back__"
    return
  fi

  if [ -z "$value" ] || ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "$DEFAULT_TIME_RANGE_MINUTES"
    return
  fi

  echo "$value"
}

azure_cli_available() {
  command -v az >/dev/null 2>&1
}

require_az() {
  if ! azure_cli_available; then
    notify-send "Azure" "Azure CLI is not installed"
    exit 0
  fi
}

choose_azure_subscription() {
  local subscriptions
  local chosen

  require_az

  if ! subscriptions="$(az account list --query '[].{name:name,id:id}' -o tsv 2>/dev/null)"; then
    notify-send "Azure" "Failed to list subscriptions. Login or configure az first."
    exit 1
  fi

  if [ -z "$subscriptions" ]; then
    notify-send "Azure" "No subscriptions found"
    exit 0
  fi

  chosen="$(printf "%s\n" "$subscriptions" | awk -F '\t' '{ print $1 "  " $2 }' | wofi_menu "Azure Subscription")"
  [ -z "$chosen" ] && exit 0

  echo "$chosen" | awk '{ print $NF }'
}

back_to_azure_menu() {
  "$AZURE_MENUS_DIR/menu.sh"
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

cloud_report() {
  if command -v bat >/dev/null 2>&1 && command -v less >/dev/null 2>&1; then
    bat --language=log --style=plain --color=always --paging=always
  elif command -v less >/dev/null 2>&1; then
    less -R
  elif command -v bat >/dev/null 2>&1; then
    bat --language=log --style=plain --color=always --paging=never
    printf '\nPress any key to close.' > /dev/tty
    IFS= read -rsn1 < /dev/tty
    printf '\n' > /dev/tty
  else
    cat
    printf '\nPress any key to close.' > /dev/tty
    IFS= read -rsn1 < /dev/tty
    printf '\n' > /dev/tty
  fi
}

cloud_fzf() {
  local prompt="${1:-Filter}"
  local mode="${2:-preview}"
  local output
  local status
  local key
  local preview_args=()

  if [ "$mode" != "plain" ]; then
    preview_args=(
      --preview 'line="$(printf "%b\n" {})"
plain="$(printf "%s\n" "$line" | sed "s/\x1b\[[0-9;]*m//g")"

if printf "%s\n" "$plain" | jq -C . 2>/dev/null; then
  exit 0
fi

json_object="$(printf "%s\n" "$plain" | sed "s/^[^{]*//")"
if [ -n "$json_object" ] && [ "$json_object" != "$plain" ] && printf "%s\n" "$json_object" | jq -C . 2>/dev/null; then
  exit 0
fi

json_array="$(printf "%s\n" "$plain" | sed "s/^[^[]*//")"
if [ -n "$json_array" ] && [ "$json_array" != "$plain" ] && printf "%s\n" "$json_array" | jq -C . 2>/dev/null; then
  exit 0
fi

printf "%s\n" "$line" | bat --style=plain --color=always --language=log 2>/dev/null || printf "%s\n" "$line"'
      --preview-window 'right,50%,wrap'
    )
  fi

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
      --header="C-y copy  Enter print  Esc close" \
      "${preview_args[@]}" \
      --bind 'ctrl-y:execute-silent(printf "%b\n" {} | sed "s/\x1b\[[0-9;]*m//g" | wl-copy)' \
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
  local window_mode="${4:-normal}"
  local temp_script

  temp_script="$(mktemp /tmp/azure-ops.XXXXXX.sh)"

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

if [ "$close_mode" = "close-on-key" ]; then
  echo
  echo "────────────────────────────────────────"
  echo "Exit code: \$status"
  echo "Press any key to close."
  echo "────────────────────────────────────────"
  IFS= read -rsn1
  exit "\$status"
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
  if [ "$window_mode" = "toggle" ]; then
    kitty --class cloud-terminal --title "$title" "$temp_script"
  else
    kitty --title "$title" "$temp_script"
  fi
}
