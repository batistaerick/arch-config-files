#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"

run_in_kitty "GCP Compute - $project" "
cloud_header 'GCP compute instances'
cloud_kv 'Project' '$project'
echo

gcloud compute instances list --project '$project' --format=json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  zone=\(.zone | split(\"/\")[-1])  status=\(.status)  machine=\(.machineType | split(\"/\")[-1])\"' \
| cloud_fzf 'Instances' plain
" close-on-success toggle
