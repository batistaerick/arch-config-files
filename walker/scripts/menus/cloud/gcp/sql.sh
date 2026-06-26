#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"

run_in_kitty "GCP SQL - $project" "
cloud_header 'GCP Cloud SQL instances'
cloud_kv 'Project' '$project'
echo

gcloud sql instances list --project '$project' --format=json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  db=\(.databaseVersion)  region=\(.region)  tier=\(.settings.tier)  state=\(.state)\"' \
| cloud_fzf 'Cloud SQL' plain
" close-on-success toggle
