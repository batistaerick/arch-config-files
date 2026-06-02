#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

if [ -z "$AWS_PROFILE" ]; then
  exit 0
fi

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
| aws_fzf 'DB instances'
"
    ;;

  "󰘦  DB clusters")
    run_in_kitty "RDS Clusters - $AWS_PROFILE" "
aws_header 'RDS / Aurora clusters'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) rds describe-db-clusters \
| jq -r '.DBClusters[] | \"\u001b[36m\(.DBClusterIdentifier)\u001b[0m  engine=\(.Engine)  status=\(.Status)  endpoint=\(.Endpoint // \"N/A\")\"' \
| aws_fzf 'DB clusters'
"
    ;;

  "󰅟  Instance status")
    run_in_kitty "RDS Status - $AWS_PROFILE" "
aws_header 'RDS instance status'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) rds describe-db-instances \
| jq -r '.DBInstances[] | \"\u001b[36m\(.DBInstanceIdentifier)\u001b[0m
\u001b[34mStatus:\u001b[0m \(.DBInstanceStatus)
\u001b[34mEngine:\u001b[0m \(.Engine)
\u001b[34mClass:\u001b[0m \(.DBInstanceClass)
\u001b[34mStorage:\u001b[0m \(.AllocatedStorage) GB
\u001b[34mMultiAZ:\u001b[0m \(.MultiAZ)
\u001b[34mEndpoint:\u001b[0m \(.Endpoint.Address // \"N/A\")
\"'
"
    ;;

  "󰕢  Recent DB events")
    run_in_kitty "RDS Events - $AWS_PROFILE" "
aws_header 'Recent RDS events'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) rds describe-events \
  --duration 60 \
| jq -r '.Events[] | \"\u001b[90m\(.Date)\u001b[0m  \u001b[36m\(.SourceIdentifier // \"N/A\")\u001b[0m  \(.Message)\"' \
| aws_fzf 'DB events'
"
    ;;

  "")
    exit 0
    ;;
esac
