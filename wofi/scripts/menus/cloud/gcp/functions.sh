#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"

run_in_kitty "GCP Functions - $project" "
cloud_header 'GCP Cloud Functions'
cloud_kv 'Project' '$project'
echo

gcloud functions list --project '$project' --format=json \
| jq -r '.[] | \"\u001b[36m\(.name | split(\"/\")[-1])\u001b[0m  runtime=\(.buildConfig.runtime // .runtime // \"N/A\")  state=\(.state // .status // \"N/A\")  url=\(.serviceConfig.uri // .httpsTrigger.url // \"N/A\")\"' \
| cloud_fzf 'Functions' plain
" close-on-success toggle
