#!/usr/bin/env bash

AWS_REGION="eu-central-1"

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
AWS_MENUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_GROUP="doola-data-logs"

ECS_CLUSTER="doola-data-cluster"
ECS_SERVICE="doola-data-ecs-service"

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

  value=$(wofi_menu "Minutes" \
    "1" \
    "2" \
    "3" \
    "5" \
    "10" \
    "15" \
    "30" \
    "60" \
    "120" \
    "360" \
    "1440")

  if [ -z "$value" ]; then
    echo "$DEFAULT_TIME_RANGE_MINUTES"
    return
  fi

  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "$DEFAULT_TIME_RANGE_MINUTES"
    return
  fi

  echo "$value"
}

ask_search_word() {
  local value

  value=$(printf "" | wofi \
    --dmenu \
    --no-sort \
    --matching=contains \
    --cache-file /dev/null \
    --prompt "Search word")

  echo "$value"
}

now_ms() {
  date +%s%3N
}

minutes_ago_ms() {
  date -d "$1 minutes ago" +%s%3N
}

aws_base() {
  echo "aws --profile \"$AWS_PROFILE\" --region \"$AWS_REGION\""
}

aws_cli() {
  aws --profile "$AWS_PROFILE" --region "$AWS_REGION" "$@"
}

shell_quote() {
  printf "%q" "$1"
}

back_to_aws_menu() {
  "$AWS_MENUS_DIR/menu.sh" "$AWS_PROFILE"
}

aws_terminal_helpers() {
  cat <<'EOF'
aws_reset=$'\033[0m'
aws_bold=$'\033[1m'
aws_dim=$'\033[2m'
aws_red=$'\033[31m'
aws_green=$'\033[32m'
aws_yellow=$'\033[33m'
aws_blue=$'\033[34m'
aws_magenta=$'\033[35m'
aws_cyan=$'\033[36m'
aws_gray=$'\033[90m'

aws_header() {
  printf '\n%s%s%s\n' "$aws_bold$aws_cyan" "$1" "$aws_reset"
  printf '%s\n' "${aws_dim}────────────────────────────────────────${aws_reset}"
}

aws_kv() {
  printf '%s%-12s%s %s\n' "$aws_blue" "$1:" "$aws_reset" "$2"
}

aws_success() {
  printf '%s%s%s\n' "$aws_green" "$1" "$aws_reset"
}

aws_warn() {
  printf '%s%s%s\n' "$aws_yellow" "$1" "$aws_reset"
}

aws_error() {
  printf '%s%s%s\n' "$aws_red" "$1" "$aws_reset"
}

aws_json() {
  if command -v bat >/dev/null 2>&1; then
    bat --language=json --style=plain --color=always
  else
    jq -C .
  fi
}

aws_fzf() {
  local prompt="${1:-Filter}"
  local mode="${2:-preview}"
  local output
  local status
  local key
  local preview_args=()

  if [ "$mode" != "plain" ]; then
    preview_args=(
      --preview 'printf "%b\n" {} | bat --style=plain --color=always --language=log 2>/dev/null || printf "%b\n" {}'
      --preview-window 'down,35%,wrap'
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
      --header="Type to filter. Enter prints selection. Esc closes." \
      "${preview_args[@]}" \
      --expect=ctrl-c,esc)"
    status=$?

    if [ "$status" -ne 0 ]; then
      if [ "$status" -eq 130 ]; then
        return 130
      fi

      return 0
    fi

    key="${output%%$'\n'*}"

    case "$key" in
      ctrl-c)
        return 130
        ;;
      esc)
        return 0
        ;;
    esac

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

  temp_script="$(mktemp /tmp/aws-ops.XXXXXX.sh)"

cat > "$temp_script" <<EOF
#!/usr/bin/env bash

set -o pipefail

export AWS_PROFILE="$AWS_PROFILE"
export AWS_REGION="$AWS_REGION"

clear

$(aws_terminal_helpers)

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
