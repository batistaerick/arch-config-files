#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/gcp/common.sh"

project="$(choose_gcp_project)"

run_in_kitty "GCP IAM - $project" "
cloud_header 'GCP IAM bindings'
cloud_kv 'Project' '$project'
echo

gcloud projects get-iam-policy '$project' --format=json \
| jq -r '.bindings[] | \"\u001b[36m\(.role)\u001b[0m  members=\(.members | join(\", \"))\"' \
| cloud_fzf 'IAM bindings'
" close-on-success toggle
