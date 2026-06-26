#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"

run_in_kitty "GCP Artifact Registry - $project" "
cloud_header 'GCP Artifact Registry repositories'
cloud_kv 'Project' '$project'
echo

gcloud artifacts repositories list --project '$project' --format=json \
| jq -r '.[] | \"\u001b[36m\(.name | split(\"/\")[-1])\u001b[0m  location=\(.name | split(\"/\")[3])  format=\(.format)  mode=\(.mode // \"STANDARD\")\"' \
| cloud_fzf 'Repositories' plain
" close-on-success toggle
