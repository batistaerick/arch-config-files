#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"

run_in_kitty "GCP GKE - $project" "
cloud_header 'GCP GKE clusters'
cloud_kv 'Project' '$project'
echo

gcloud container clusters list --project '$project' --format=json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  location=\(.location)  status=\(.status)  version=\(.currentMasterVersion // \"N/A\")\"' \
| cloud_fzf 'GKE clusters' plain
" close-on-success toggle
