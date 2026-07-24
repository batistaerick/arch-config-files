#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

if [ -z "$AWS_PROFILE" ]; then
  exit 0
fi

choose_db_instance() {
  local instances
  local chosen

  if ! instances="$(aws_cli rds describe-db-instances | jq -r '.DBInstances[].DBInstanceIdentifier')"; then
    notify-send "RDS" "Failed to list DB instances for $AWS_PROFILE"
    exit 1
  fi

  if [ -z "$instances" ]; then
    notify-send "RDS" "No DB instances found for $AWS_PROFILE"
    exit 0
  fi

  chosen="$(printf "%s\n" "$instances" | wofi_menu "DB Instance")"

  if [ -z "$chosen" ]; then
    exit 0
  fi

  echo "$chosen"
}

choose_db_cluster() {
  local clusters
  local chosen

  if ! clusters="$(aws_cli rds describe-db-clusters | jq -r '.DBClusters[].DBClusterIdentifier')"; then
    notify-send "RDS" "Failed to list DB clusters for $AWS_PROFILE"
    exit 1
  fi

  if [ -z "$clusters" ]; then
    notify-send "RDS" "No DB clusters found for $AWS_PROFILE"
    exit 0
  fi

  chosen="$(printf "%s\n" "$clusters" | wofi_menu "DB Cluster")"

  if [ -z "$chosen" ]; then
    exit 0
  fi

  echo "$chosen"
}

options="←  Back
  DB instances
󰘦  DB clusters
󰅟  Instance status
󰕢  Recent DB events"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="Aurora / RDS - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "  DB instances")
    run_in_kitty "RDS Instances - $AWS_PROFILE" "
aws_header 'RDS DB instances'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) rds describe-db-instances \
| jq -r '.DBInstances[] | \"\u001b[36m\(.DBInstanceIdentifier)\u001b[0m  engine=\(.Engine)  status=\(.DBInstanceStatus)  class=\(.DBInstanceClass)\"' \
| aws_fzf 'DB instances' plain
" close-on-success toggle
    ;;

  "󰘦  DB clusters")
    run_in_kitty "RDS Clusters - $AWS_PROFILE" "
aws_header 'RDS / Aurora clusters'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) rds describe-db-clusters \
| jq -r '.DBClusters[] | \"\u001b[36m\(.DBClusterIdentifier)\u001b[0m  engine=\(.Engine)  status=\(.Status)  endpoint=\(.Endpoint // \"N/A\")\"' \
| aws_fzf 'DB clusters' plain
" close-on-success toggle
    ;;

  "󰅟  Instance status")
    instance="$(choose_db_instance)"
    quoted_instance="$(shell_quote "$instance")"

    run_in_kitty "RDS Status - $AWS_PROFILE" "
aws_header 'RDS instance status'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Instance' $quoted_instance
echo

$(aws_base) rds describe-db-instances \
  --db-instance-identifier $quoted_instance \
| jq -r '.DBInstances[] | \"\u001b[36m\(.DBInstanceIdentifier)\u001b[0m
\u001b[34mStatus:\u001b[0m \(.DBInstanceStatus)
\u001b[34mEngine:\u001b[0m \(.Engine)
\u001b[34mClass:\u001b[0m \(.DBInstanceClass)
\u001b[34mStorage:\u001b[0m \(.AllocatedStorage) GB
\u001b[34mMultiAZ:\u001b[0m \(.MultiAZ)
\u001b[34mEndpoint:\u001b[0m \(.Endpoint.Address // \"N/A\")
\"' \
| aws_report
" close-on-success toggle
    ;;

  "󰕢  Recent DB events")
    source_type="$(wofi_menu "Event source type" "DB instance" "DB cluster")"

    case "$source_type" in
      "DB instance")
        source_id="$(choose_db_instance)"
        ;;
      "DB cluster")
        source_id="$(choose_db_cluster)"
        ;;
      "")
        exit 0
        ;;
    esac

    quoted_source_id="$(shell_quote "$source_id")"

    run_in_kitty "RDS Events - $AWS_PROFILE" "
aws_header 'Recent RDS events'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Source' $quoted_source_id
echo

$(aws_base) rds describe-events \
  --source-identifier $quoted_source_id \
  --duration 60 \
| jq -r '.Events[] | \"\u001b[90m\(.Date)\u001b[0m  \u001b[36m\(.SourceIdentifier // \"N/A\")\u001b[0m  \(.Message)\"' \
| aws_report
" close-on-success toggle
    ;;

  "")
    exit 0
    ;;
esac
