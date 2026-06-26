#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"
minutes="$(choose_time_range_minutes)"

if [ "$minutes" = "__back__" ]; then
  back_to_gcp_menu
  exit 0
fi

since="$(date -u -d "$minutes minutes ago" '+%Y-%m-%dT%H:%M:%SZ')"

run_in_kitty "GCP Logs - $project" "
cloud_header 'GCP logs'
cloud_kv 'Project' '$project'
cloud_kv 'Since' '$since'
echo

gcloud logging read 'timestamp >= \"$since\"' --project '$project' --limit=300 --format=json \
| jq -r '.[] | \"\u001b[90m\(.timestamp)\u001b[0m  \u001b[36m\(.resource.type)\u001b[0m  \((.severity // \"DEFAULT\"))  \((.textPayload // .jsonPayload.message // .protoPayload.methodName // \"\"))\"' \
| cloud_fzf 'Logs'
" close-on-success toggle
