#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

[ -z "$AWS_PROFILE" ] && exit 0

choose_docdb_cluster() {
  local clusters chosen

  if ! clusters="$(aws_cli docdb describe-db-clusters | jq -r '.DBClusters[].DBClusterIdentifier')"; then
    notify-send "DocumentDB" "Failed to list clusters"
    exit 1
  fi

  [ -z "$clusters" ] && notify-send "DocumentDB" "No clusters found" && exit 0
  chosen="$(printf "%s\n" "$clusters" | wofi_menu "DocumentDB Cluster")"
  [ -z "$chosen" ] && exit 0
  echo "$chosen"
}

options="←  Back
󰘦  Clusters
  Instances
󰅟  Cluster details
󰕢  Recent events"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="DocumentDB - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "󰘦  Clusters")
    run_in_kitty "DocumentDB Clusters - $AWS_PROFILE" "
aws_header 'DocumentDB clusters'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) docdb describe-db-clusters \
| jq -r '.DBClusters[] | \"\u001b[36m\(.DBClusterIdentifier)\u001b[0m  status=\(.Status)  engine=\(.Engine)  endpoint=\(.Endpoint // \"N/A\")\"' \
| aws_fzf 'Clusters' plain
" close-on-success toggle
    ;;
  "  Instances")
    run_in_kitty "DocumentDB Instances - $AWS_PROFILE" "
aws_header 'DocumentDB instances'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) docdb describe-db-instances \
| jq -r '.DBInstances[] | \"\u001b[36m\(.DBInstanceIdentifier)\u001b[0m  cluster=\(.DBClusterIdentifier // \"N/A\")  status=\(.DBInstanceStatus)  class=\(.DBInstanceClass)\"' \
| aws_fzf 'Instances' plain
" close-on-success toggle
    ;;
  "󰅟  Cluster details")
    cluster="$(choose_docdb_cluster)"
    quoted_cluster="$(shell_quote "$cluster")"

    run_in_kitty "DocumentDB Cluster - $AWS_PROFILE" "
aws_header 'DocumentDB cluster details'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Cluster' $quoted_cluster
echo

$(aws_base) docdb describe-db-clusters --db-cluster-identifier $quoted_cluster | aws_json
" close-on-success toggle
    ;;
  "󰕢  Recent events")
    cluster="$(choose_docdb_cluster)"
    quoted_cluster="$(shell_quote "$cluster")"

    run_in_kitty "DocumentDB Events - $AWS_PROFILE" "
aws_header 'DocumentDB recent events'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Cluster' $quoted_cluster
echo

$(aws_base) docdb describe-events --source-identifier $quoted_cluster --duration 60 \
| jq -r '.Events[] | \"\u001b[90m\(.Date)\u001b[0m  \u001b[36m\(.SourceIdentifier // \"N/A\")\u001b[0m  \(.Message)\"' \
| aws_fzf 'Events'
" close-on-success toggle
    ;;
  "")
    exit 0
    ;;
esac
