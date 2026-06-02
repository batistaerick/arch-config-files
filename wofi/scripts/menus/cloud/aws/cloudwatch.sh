#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

if [ -z "$AWS_PROFILE" ]; then
  exit 0
fi

cloudwatch_logs_command() {
  local filter_pattern="$1"
  local minutes="$2"
  local quoted_filter_pattern

  quoted_filter_pattern="$(shell_quote "$filter_pattern")"

  cat <<EOF
aws_header "CloudWatch logs"
aws_kv "Profile" "$AWS_PROFILE"
aws_kv "Log group" "$LOG_GROUP"
aws_kv "Filter" $quoted_filter_pattern
aws_kv "Minutes" "$minutes"
echo

$(aws_base) logs filter-log-events \\
  --log-group-name "$LOG_GROUP" \\
  --filter-pattern $quoted_filter_pattern \\
  --start-time $(minutes_ago_ms "$minutes") \\
  --end-time $(now_ms) \\
| jq -r '
  if (.events | length) == 0 then
    "No logs found."
  else
    .events[]
    | "\u001b[90m\(.timestamp / 1000 | todate)\u001b[0m  \(.message
        | gsub("ERROR"; "\u001b[31mERROR\u001b[0m")
        | gsub("WARN"; "\u001b[33mWARN\u001b[0m")
        | gsub("INFO"; "\u001b[36mINFO\u001b[0m"))"
  end
' | aws_fzf "Logs"
EOF
}

search_word_logs_command() {
  local word="$1"
  local minutes="$2"
  local quoted_word

  quoted_word="$(shell_quote "$word")"

  cat <<EOF
aws_header "CloudWatch search"
aws_kv "Profile" "$AWS_PROFILE"
aws_kv "Log group" "$LOG_GROUP"
aws_kv "Word" $quoted_word
aws_kv "Minutes" "$minutes"
echo

$(aws_base) logs filter-log-events \\
  --log-group-name "$LOG_GROUP" \\
  --filter-pattern $quoted_word \\
  --start-time $(minutes_ago_ms "$minutes") \\
  --end-time $(now_ms) \\
| jq -r '
  if (.events | length) == 0 then
    "No logs found."
  else
    .events[]
    | "\u001b[90m\(.timestamp / 1000 | todate)\u001b[0m  \u001b[36m\(.logStreamName)\u001b[0m  \(.message)"
  end
' | aws_fzf "Logs"
EOF
}

latest_streams_command() {
  cat <<EOF
aws_header "Latest CloudWatch log streams"
aws_kv "Profile" "$AWS_PROFILE"
aws_kv "Log group" "$LOG_GROUP"
echo

$(aws_base) logs describe-log-streams \\
  --log-group-name "$LOG_GROUP" \\
  --order-by LastEventTime \\
  --descending \\
  --max-items 20 \\
| jq -r '
  if (.logStreams | length) == 0 then
    "No log streams found."
  else
    .logStreams[]
    | "\u001b[90m\(.lastEventTimestamp / 1000 | todate)\u001b[0m  \u001b[36m\(.logStreamName)\u001b[0m"
  end
' | aws_fzf "Streams"
EOF
}

options="←  Back
  ERROR logs
  WARN logs
  INFO logs
  Search word
󰁫  Latest log streams"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="CloudWatch - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "  ERROR logs")
    minutes="$(choose_time_range_minutes)"
    run_in_kitty "CloudWatch ERROR - $AWS_PROFILE" "$(cloudwatch_logs_command "ERROR" "$minutes")"
    ;;
  "  WARN logs")
    minutes="$(choose_time_range_minutes)"
    run_in_kitty "CloudWatch WARN - $AWS_PROFILE" "$(cloudwatch_logs_command "WARN" "$minutes")"
    ;;
  "  INFO logs")
    minutes="$(choose_time_range_minutes)"
    run_in_kitty "CloudWatch INFO - $AWS_PROFILE" "$(cloudwatch_logs_command "INFO" "$minutes")"
    ;;
  "  Search word")
    word="$(ask_search_word)"

    if [ -z "$word" ]; then
      exit 0
    fi

    minutes="$(choose_time_range_minutes)"
    run_in_kitty "CloudWatch Search - $AWS_PROFILE" "$(search_word_logs_command "$word" "$minutes")"
    ;;
  "󰁫  Latest log streams")
    run_in_kitty "CloudWatch Streams - $AWS_PROFILE" "$(latest_streams_command)"
    ;;
  "")
    exit 0
    ;;
esac
