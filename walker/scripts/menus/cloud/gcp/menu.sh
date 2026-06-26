#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/gcp/common.sh"

case "${1:-}" in
  --login)
    if ! gcp_cli_available; then
      notify-send "GCP" "gcloud CLI is not installed"
      exit 0
    fi
    run_in_kitty "GCP Login" "
cloud_header 'GCP login'
cloud_success 'Opening gcloud auth login...'
echo
gcloud auth login
" close-on-success
    exit 0
    ;;
  --check-auth)
    require_gcloud
    run_in_kitty "GCP Auth" "
cloud_header 'GCP auth'
gcloud auth list --format=json \
| jq -r '.[] | \"\u001b[36m\(.account)\u001b[0m  status=\(.status)\"'
" close-on-key toggle
    exit 0
    ;;
  --projects)
    require_gcloud
    run_in_kitty "GCP Projects" "
cloud_header 'GCP projects'
gcloud projects list --format=json \
| jq -r '.[] | \"\u001b[36m\(.projectId)\u001b[0m  name=\(.name)  state=\(.lifecycleState)\"' \
| cloud_fzf 'Projects' plain
" close-on-success toggle
    exit 0
    ;;
esac

options="󰊭  Login
󰅟  Check Auth
󰏗  Projects
  Compute Instances
󰉋  Storage Buckets
󰠇  GKE Clusters
󰣇  Cloud Run
󰈳  Cloud SQL
  Artifact Registry
󰊕  Cloud Functions
󰖟  VPC Networks
󰒃  IAM
󰢬  Logs"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="GCP")

case "$chosen" in
  "󰊭  Login")
    if ! gcp_cli_available; then
      notify-send "GCP" "gcloud CLI is not installed"
      exit 0
    fi
    run_in_kitty "GCP Login" "
cloud_header 'GCP login'
cloud_success 'Opening gcloud auth login...'
echo
gcloud auth login
" close-on-success
    ;;
  "󰅟  Check Auth")
    require_gcloud
    run_in_kitty "GCP Auth" "
cloud_header 'GCP auth'
gcloud auth list --format=json \
| jq -r '.[] | \"\u001b[36m\(.account)\u001b[0m  status=\(.status)\"'
" close-on-key toggle
    ;;
  "󰏗  Projects")
    require_gcloud
    run_in_kitty "GCP Projects" "
cloud_header 'GCP projects'
gcloud projects list --format=json \
| jq -r '.[] | \"\u001b[36m\(.projectId)\u001b[0m  name=\(.name)  state=\(.lifecycleState)\"' \
| cloud_fzf 'Projects' plain
" close-on-success toggle
    ;;
  "  Compute Instances")
    "$GCP_MENUS_DIR/compute.sh"
    ;;
  "󰉋  Storage Buckets")
    "$GCP_MENUS_DIR/storage.sh"
    ;;
  "󰠇  GKE Clusters")
    "$GCP_MENUS_DIR/gke.sh"
    ;;
  "󰣇  Cloud Run")
    "$GCP_MENUS_DIR/cloud-run.sh"
    ;;
  "󰈳  Cloud SQL")
    "$GCP_MENUS_DIR/sql.sh"
    ;;
  "  Artifact Registry")
    "$GCP_MENUS_DIR/artifact-registry.sh"
    ;;
  "󰊕  Cloud Functions")
    "$GCP_MENUS_DIR/functions.sh"
    ;;
  "󰖟  VPC Networks")
    "$GCP_MENUS_DIR/vpc.sh"
    ;;
  "󰒃  IAM")
    "$GCP_MENUS_DIR/iam.sh"
    ;;
  "󰢬  Logs")
    "$GCP_MENUS_DIR/logs.sh"
    ;;
  "")
    exit 0
    ;;
esac
