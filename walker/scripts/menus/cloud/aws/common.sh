#!/usr/bin/env bash

AWS_REGION="eu-central-1"

MENUS_DIR="$HOME/.config/walker/scripts/menus"
AWS_MENUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_GROUP="doola-data-logs"

ECS_CLUSTER="doola-data-cluster"
ECS_SERVICE="doola-data-ecs-service"

DEFAULT_TIME_RANGE_MINUTES="30"

walker_menu() {
  local prompt="$1"
  shift

  if [ "$#" -gt 0 ]; then
    printf "%s\n" "$@"
  else
    cat
  fi | $HOME/.config/walker/bin/walker-dmenu \
      --dmenu \
      --no-sort \
      --matching=contains \
      --cache-file /dev/null \
      --prompt "$prompt"
}

choose_time_range_minutes() {
  local value

  value=$(walker_menu "Minutes" \
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

  value=$(printf "" | $HOME/.config/walker/bin/walker-dmenu \
    --dmenu \
    --exec-search \
    --hide-scroll \
    --no-sort \
    --matching=contains \
    --cache-file /dev/null \
    --height 82 \
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
  if [ -t 1 ] && command -v bat >/dev/null 2>&1; then
    bat --language=json --style=plain --color=always
  else
    jq -C .
  fi
}

aws_report() {
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

aws_fzf() {
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
      --header="Enter print  Esc close" \
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

aws_cloudwatch_search_fzf() {
  local log_group="$1"
  local initial_word="$2"
  local minutes="$3"
  local state_file
  local minutes_file
  local helper_script
  local search_reload_command
  local time_reload_command
  local output
  local status
  local key

  if ! command -v fzf >/dev/null 2>&1; then
    AWS_CW_LOG_GROUP="$log_group" AWS_CW_MINUTES="$minutes" AWS_CW_WORD="$initial_word" bash -c '
      args=(
        logs filter-log-events
        --log-group-name "$AWS_CW_LOG_GROUP"
        --start-time "$(date -d "$AWS_CW_MINUTES minutes ago" +%s%3N)"
        --end-time "$(date +%s%3N)"
      )

      if [ -n "$AWS_CW_WORD" ]; then
        args+=(--filter-pattern "$AWS_CW_WORD")
      fi

      aws --profile "$AWS_PROFILE" --region "$AWS_REGION" "${args[@]}" \
      | jq -r ".events[].message"
    '
    return
  fi

  state_file="$(mktemp /tmp/aws-cw-query.XXXXXX)"
  minutes_file="$(mktemp /tmp/aws-cw-minutes.XXXXXX)"
  helper_script="$(mktemp /tmp/aws-cw-search.XXXXXX.sh)"

  printf '%s' "$initial_word" > "$state_file"
  printf '%s' "$minutes" > "$minutes_file"

  cat > "$helper_script" <<'AWS_CW_SEARCH_HELPER'
#!/usr/bin/env bash

set -o pipefail

prompt_mode="${1:-}"

if [ "$prompt_mode" = "search" ]; then
  new_word=""

  if command -v $HOME/.config/walker/bin/walker-dmenu >/dev/null 2>&1; then
    new_word="$(printf "" | $HOME/.config/walker/bin/walker-dmenu \
      --dmenu \
      --exec-search \
      --hide-scroll \
      --no-sort \
      --matching=contains \
      --cache-file /dev/null \
      --height 82 \
      --prompt "CloudWatch search")"
  else
    printf '\nCloudWatch search: ' > /dev/tty
    IFS= read -r new_word < /dev/tty
  fi

  if [ -n "$new_word" ]; then
    printf '%s' "$new_word" > "$AWS_CW_STATE_FILE"
  fi
elif [ "$prompt_mode" = "time" ]; then
  new_minutes=""

  if command -v $HOME/.config/walker/bin/walker-dmenu >/dev/null 2>&1; then
    new_minutes="$(printf '%s\n' "1" "2" "3" "5" "10" "15" "30" "60" "120" "360" "1440" | $HOME/.config/walker/bin/walker-dmenu \
      --dmenu \
      --no-sort \
      --matching=contains \
      --cache-file /dev/null \
      --prompt "Minutes")"
  else
    printf '\nMinutes: ' > /dev/tty
    IFS= read -r new_minutes < /dev/tty
  fi

  if [[ "$new_minutes" =~ ^[0-9]+$ ]]; then
    printf '%s' "$new_minutes" > "$AWS_CW_MINUTES_FILE"
  fi
fi

word="$(cat "$AWS_CW_STATE_FILE" 2>/dev/null || true)"
minutes="$(cat "$AWS_CW_MINUTES_FILE" 2>/dev/null || printf '%s' "$AWS_CW_MINUTES")"

display_word="$word"

if [ -z "$display_word" ]; then
  display_word="<all logs>"
fi

if [ "${#display_word}" -gt 32 ]; then
  display_word="${display_word:0:29}..."
fi

printf '\033[2mQ: %s | %sm\033[0m\n' "$display_word" "$minutes"

args=(
  logs filter-log-events
  --log-group-name "$AWS_CW_LOG_GROUP"
  --start-time "$(date -d "$minutes minutes ago" +%s%3N)"
  --end-time "$(date +%s%3N)"
)

if [ -n "$word" ]; then
  args+=(--filter-pattern "$word")
fi

if ! response="$(aws --profile "$AWS_PROFILE" --region "$AWS_REGION" "${args[@]}" 2>&1)"; then
  printf '\033[31mCloudWatch search failed:\033[0m %s\n' "$response"
  exit 0
fi

printf '%s\n' "$response" | jq -r '
  if (.events | length) == 0 then
    "No logs found."
  else
    .events[]
    | "\u001b[90m\(.timestamp / 1000 | todate)\u001b[0m  \u001b[36m\(.logStreamName)\u001b[0m  \(.message
        | gsub("ERROR"; "\u001b[31mERROR\u001b[0m")
        | gsub("WARN"; "\u001b[33mWARN\u001b[0m")
        | gsub("INFO"; "\u001b[36mINFO\u001b[0m")
        | gsub("Exception"; "\u001b[31mException\u001b[0m")
        | gsub("Traceback"; "\u001b[31mTraceback\u001b[0m")
        | gsub("failed"; "\u001b[31mfailed\u001b[0m")
        | gsub("Failed"; "\u001b[31mFailed\u001b[0m"))"
  end
'
AWS_CW_SEARCH_HELPER

  chmod +x "$helper_script"

  search_reload_command="env AWS_CW_STATE_FILE=$(printf '%q' "$state_file") AWS_CW_MINUTES_FILE=$(printf '%q' "$minutes_file") AWS_CW_LOG_GROUP=$(printf '%q' "$log_group") AWS_CW_MINUTES=$(printf '%q' "$minutes") $(printf '%q' "$helper_script") search"
  time_reload_command="env AWS_CW_STATE_FILE=$(printf '%q' "$state_file") AWS_CW_MINUTES_FILE=$(printf '%q' "$minutes_file") AWS_CW_LOG_GROUP=$(printf '%q' "$log_group") AWS_CW_MINUTES=$(printf '%q' "$minutes") $(printf '%q' "$helper_script") time"

  output="$(env AWS_CW_STATE_FILE="$state_file" AWS_CW_MINUTES_FILE="$minutes_file" AWS_CW_LOG_GROUP="$log_group" AWS_CW_MINUTES="$minutes" "$helper_script" \
    | fzf \
      --ansi \
      --no-sort \
      --cycle \
      --height=100% \
      --layout=reverse \
      --border \
      --color='fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8,info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc,marker:#a6e3a1,spinner:#f9e2af,header:#94e2d5,border:#89b4fa' \
      --prompt="Logs > " \
      --header="C-s search  C-t time  C-y copy  Esc close" \
      --header-lines=1 \
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

printf "%s\n" "$line" | bat --style=plain --color=always --language=log 2>/dev/null || printf "%s\n" "$line"' \
      --preview-window 'right,50%,wrap' \
      --bind "ctrl-s:reload($search_reload_command)+clear-query" \
      --bind "ctrl-t:reload($time_reload_command)+clear-query" \
      --bind 'ctrl-y:execute-silent(printf "%b\n" {} | sed "s/\x1b\[[0-9;]*m//g" | wl-copy)' \
      --expect=ctrl-c,esc)"
  status=$?

  rm -f "$state_file" "$minutes_file" "$helper_script"

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
