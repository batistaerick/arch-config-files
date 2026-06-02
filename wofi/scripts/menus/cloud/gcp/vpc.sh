#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"

run_in_kitty "GCP VPC - $project" "
cloud_header 'GCP VPC networks'
cloud_kv 'Project' '$project'
echo

gcloud compute networks list --project '$project' --format=json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  mode=\(.routingConfig.routingMode // \"N/A\")  subnets=\(.subnetworks | length)  autoCreate=\(.autoCreateSubnetworks)\"' \
| cloud_fzf 'VPC networks' plain
" close-on-success toggle
