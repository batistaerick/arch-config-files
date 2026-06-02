#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

if [ -z "$AWS_PROFILE" ]; then
  exit 0
fi

service_status_command() {
  cat <<EOF
aws_header "ECS service status"
aws_kv "Profile" "$AWS_PROFILE"
aws_kv "Cluster" "$ECS_CLUSTER"
aws_kv "Service" "$ECS_SERVICE"
echo

$(aws_base) ecs describe-services \\
  --cluster "$ECS_CLUSTER" \\
  --services "$ECS_SERVICE" \\
| jq -r '
  if (.services | length) == 0 then
    "No ECS service found."
  else
    .services[] |
    "\u001b[36mService:\u001b[0m \(.serviceName)
\u001b[34mStatus:\u001b[0m \(.status)
\u001b[34mDesired:\u001b[0m \(.desiredCount)
\u001b[34mRunning:\u001b[0m \(.runningCount)
\u001b[34mPending:\u001b[0m \(.pendingCount)

\u001b[35mDeployments:\u001b[0m
" +
    (
      [.deployments[]
        | "- \u001b[36m\(.status)\u001b[0m | desired=\(.desiredCount) running=\(.runningCount) pending=\(.pendingCount) rollout=\(.rolloutState // "N/A") reason=\(.rolloutStateReason // "N/A")"
      ] | join("\n")
    )
  end
'
EOF
}

service_events_command() {
  cat <<EOF
aws_header "ECS service events"
aws_kv "Profile" "$AWS_PROFILE"
aws_kv "Cluster" "$ECS_CLUSTER"
aws_kv "Service" "$ECS_SERVICE"
echo

$(aws_base) ecs describe-services \\
  --cluster "$ECS_CLUSTER" \\
  --services "$ECS_SERVICE" \\
| jq -r '
  if (.services | length) == 0 then
    "No ECS service found."
  elif (.services[0].events | length) == 0 then
    "No ECS service events found."
  else
    .services[0].events[:30][]
    | "\u001b[90m\(.createdAt)\u001b[0m  \(.message)"
  end
' | aws_fzf "Events"
EOF
}

running_tasks_command() {
  cat <<EOF
aws_header "Running ECS tasks"
aws_kv "Profile" "$AWS_PROFILE"
aws_kv "Cluster" "$ECS_CLUSTER"
aws_kv "Service" "$ECS_SERVICE"
echo

TASKS=\$($(aws_base) ecs list-tasks \\
  --cluster "$ECS_CLUSTER" \\
  --service-name "$ECS_SERVICE" \\
  --desired-status RUNNING \\
  | jq -r '.taskArns[]')

if [ -z "\$TASKS" ]; then
  echo "No running tasks found."
  exit 0
fi

$(aws_base) ecs describe-tasks \\
  --cluster "$ECS_CLUSTER" \\
  --tasks \$TASKS \\
| jq -r '
  .tasks[]
  | "\u001b[36m\(.taskArn | split("/")[-1])\u001b[0m  last=\(.lastStatus) desired=\(.desiredStatus) health=\(.healthStatus // "N/A") started=\(.startedAt // "N/A") cpu=\(.cpu // "N/A") memory=\(.memory // "N/A")"
' | aws_fzf "Running tasks"
EOF
}

stopped_tasks_command() {
  cat <<EOF
aws_header "Recently stopped ECS tasks"
aws_kv "Profile" "$AWS_PROFILE"
aws_kv "Cluster" "$ECS_CLUSTER"
aws_kv "Service" "$ECS_SERVICE"
echo

TASKS=\$($(aws_base) ecs list-tasks \\
  --cluster "$ECS_CLUSTER" \\
  --service-name "$ECS_SERVICE" \\
  --desired-status STOPPED \\
  --max-results 10 \\
  | jq -r '.taskArns[]')

if [ -z "\$TASKS" ]; then
  echo "No recently stopped tasks found."
  exit 0
fi

$(aws_base) ecs describe-tasks \\
  --cluster "$ECS_CLUSTER" \\
  --tasks \$TASKS \\
| jq -r '
  .tasks[]
  | "\u001b[36m\(.taskArn | split("/")[-1])\u001b[0m  code=\(.stopCode // "N/A") stopped=\(.stoppedAt // "N/A") reason=\(.stoppedReason // "N/A") containers=\([.containers[] | "\(.name):exit=\(.exitCode // "N/A") reason=\(.reason // "N/A")"] | join("; "))"
' | aws_fzf "Stopped tasks"
EOF
}

list_clusters_command() {
  cat <<EOF
aws_header "ECS clusters"
aws_kv "Profile" "$AWS_PROFILE"
echo

$(aws_base) ecs list-clusters | jq -r '.clusterArns[] | "\u001b[36m\(split("/")[-1])\u001b[0m  \u001b[90m\(.)\u001b[0m"' | aws_fzf "Clusters"
EOF
}

list_services_command() {
  cat <<EOF
aws_header "ECS services"
aws_kv "Profile" "$AWS_PROFILE"
aws_kv "Cluster" "$ECS_CLUSTER"
echo

$(aws_base) ecs list-services \\
  --cluster "$ECS_CLUSTER" \\
| jq -r '.serviceArns[] | "\u001b[36m\(split("/")[-1])\u001b[0m  \u001b[90m\(.)\u001b[0m"' \
| aws_fzf "Services"
EOF
}

options="←  Back
󰅟  Service status
󰑓  Service events
󰐱  Running tasks
  Stopped tasks
󰌗  List clusters
󰓾  List services"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="ECS - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "󰅟  Service status")
    run_in_kitty "ECS Status - $AWS_PROFILE" "$(service_status_command)"
    ;;
  "󰑓  Service events")
    run_in_kitty "ECS Events - $AWS_PROFILE" "$(service_events_command)"
    ;;
  "󰐱  Running tasks")
    run_in_kitty "ECS Running Tasks - $AWS_PROFILE" "$(running_tasks_command)"
    ;;
  "  Stopped tasks")
    run_in_kitty "ECS Stopped Tasks - $AWS_PROFILE" "$(stopped_tasks_command)"
    ;;
  "󰌗  List clusters")
    run_in_kitty "ECS Clusters - $AWS_PROFILE" "$(list_clusters_command)"
    ;;
  "󰓾  List services")
    run_in_kitty "ECS Services - $AWS_PROFILE" "$(list_services_command)"
    ;;
  "")
    exit 0
    ;;
esac
