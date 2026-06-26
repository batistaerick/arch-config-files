#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"

run_in_kitty "GCP Storage - $project" "
cloud_header 'GCP storage buckets'
cloud_kv 'Project' '$project'
echo

gcloud storage buckets list --project '$project' --format=json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  location=\(.location)  class=\(.storageClass)\"' \
| cloud_fzf 'Buckets' plain
" close-on-success toggle
