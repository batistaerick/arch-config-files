#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"

run_in_kitty "GCP Cloud Run - $project" "
cloud_header 'GCP Cloud Run services'
cloud_kv 'Project' '$project'
echo

gcloud run services list --project '$project' --format=json \
| jq -r '.[] | \"\u001b[36m\(.metadata.name)\u001b[0m  region=\(.metadata.labels[\"cloud.googleapis.com/location\"] // \"N/A\")  url=\(.status.url // \"N/A\")\"' \
| cloud_fzf 'Cloud Run' plain
" close-on-success toggle
