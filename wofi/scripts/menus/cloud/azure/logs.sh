#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/azure/common.sh"

subscription="$(choose_azure_subscription)"
minutes="$(choose_time_range_minutes)"

if [ "$minutes" = "__back__" ]; then
  back_to_azure_menu
  exit 0
fi

start_time="$(date -u -d "$minutes minutes ago" '+%Y-%m-%dT%H:%M:%SZ')"

run_in_kitty "Azure Activity Logs" "
cloud_header 'Azure activity logs'
cloud_kv 'Subscription' '$subscription'
cloud_kv 'Since' '$start_time'
echo

az monitor activity-log list --subscription '$subscription' --start-time '$start_time' -o json \
| jq -r '.[] | \"\u001b[90m\(.eventTimestamp)\u001b[0m  \u001b[36m\(.resourceGroupName // \"N/A\")\u001b[0m  status=\(.status.value // \"N/A\")  \(.operationName.localizedValue // .operationName.value // \"\")\"' \
| cloud_fzf 'Activity'
" close-on-success toggle
