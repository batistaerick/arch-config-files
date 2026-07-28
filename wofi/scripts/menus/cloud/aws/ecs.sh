#!/usr/bin/env bash

AWS_PROFILE="${1:-}"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

if [ -z "$AWS_PROFILE" ]; then
  exit 0
fi

choose_ecs_cluster() {
  local clusters
  local chosen

  if ! clusters="$(aws_cli ecs list-clusters | jq -r '.clusterArns[] | split("/")[-1]')"; then
    notify-send "ECS" "Failed to list clusters for $AWS_PROFILE"
    exit 1
  fi

  if [ -z "$clusters" ]; then
    notify-send "ECS" "No clusters found for $AWS_PROFILE"
    exit 0
  fi

  chosen="$(printf "%s\n" "$clusters" | wofi_menu "ECS Cluster")"

  if [ -z "$chosen" ]; then
    exit 0
  fi

  echo "$chosen"
}

choose_ecs_service() {
  local cluster="$1"
  local services
  local chosen

  if ! services="$(aws_cli ecs list-services \
    --cluster "$cluster" \
    | jq -r '.serviceArns[] | split("/")[-1]')"; then
    notify-send "ECS" "Failed to list services in $cluster"
    exit 1
  fi

  if [ -z "$services" ]; then
    notify-send "ECS" "No services found in $cluster"
    exit 0
  fi

  chosen="$(printf "%s\n" "$services" | wofi_menu "ECS Service")"

  if [ -z "$chosen" ]; then
    exit 0
  fi

  echo "$chosen"
}

ECS_CLUSTER="$(choose_ecs_cluster)"
ECS_SERVICE="$(choose_ecs_service "$ECS_CLUSTER")"
printf -v RETURN_TO_ECS_COMMAND "%q %q" "$0" "$AWS_PROFILE"

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
' | aws_report
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
' | aws_report
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
' | aws_report
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
' | aws_report
EOF
}

deployments_command() {
  cat <<EOF
aws_header "ECS deployments"
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
  elif (.services[0].deployments | length) == 0 then
    "No ECS deployments found."
  else
    .services[0].deployments[]
    | "\u001b[36m\(.status)\u001b[0m  id=\(.id | split("/")[-1]) desired=\(.desiredCount) running=\(.runningCount) pending=\(.pendingCount) failed=\(.failedTasks) rollout=\(.rolloutState // "N/A") created=\(.createdAt) updated=\(.updatedAt) reason=\(.rolloutStateReason // "N/A")"
  end
' | aws_report
EOF
}

deployment_logs_command() {
  cat <<EOF
aws_header "ECS latest deployment logs"
aws_kv "Profile" "$AWS_PROFILE"
aws_kv "Cluster" "$ECS_CLUSTER"
aws_kv "Service" "$ECS_SERVICE"
aws_kv "Log group" "$LOG_GROUP"
echo

SERVICE_JSON=\$($(aws_base) ecs describe-services \\
  --cluster "$ECS_CLUSTER" \\
  --services "$ECS_SERVICE")

DEPLOYMENT_START=\$(printf '%s' "\$SERVICE_JSON" | jq -r '
  [.services[0].deployments[]?.createdAt]
  | sort
  | last
  // empty
')

if [ -n "\$DEPLOYMENT_START" ]; then
  START_MS=\$(date -d "\$DEPLOYMENT_START" +%s%3N 2>/dev/null || date -d "60 minutes ago" +%s%3N)
  aws_kv "Since" "\$DEPLOYMENT_START"
else
  START_MS=\$(date -d "60 minutes ago" +%s%3N)
  aws_warn "Could not find deployment start time. Falling back to the last 60 minutes."
fi

echo

$(aws_base) logs filter-log-events \\
  --log-group-name "$LOG_GROUP" \\
  --start-time "\$START_MS" \\
  --end-time $(now_ms) \\
  --max-items 300 \\
| jq -r '
  if (.events | length) == 0 then
    "No logs found for the latest deployment window."
  else
    .events[]
    | "\u001b[90m\(.timestamp / 1000 | todate)\u001b[0m  \u001b[36m\(.logStreamName)\u001b[0m  \(.message
        | gsub("ERROR"; "\u001b[31mERROR\u001b[0m")
        | gsub("WARN"; "\u001b[33mWARN\u001b[0m")
        | gsub("Exception"; "\u001b[31mException\u001b[0m")
        | gsub("Traceback"; "\u001b[31mTraceback\u001b[0m")
        | gsub("failed"; "\u001b[31mfailed\u001b[0m")
        | gsub("Failed"; "\u001b[31mFailed\u001b[0m"))"
  end
' | aws_fzf "Deployment logs"
EOF
}

list_clusters_command() {
  cat <<EOF
aws_header "ECS clusters"
aws_kv "Profile" "$AWS_PROFILE"
echo

$(aws_base) ecs list-clusters | jq -r '.clusterArns[] | "\u001b[36m\(split("/")[-1])\u001b[0m  \u001b[90m\(.)\u001b[0m"' | aws_fzf "Clusters" plain
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
| aws_fzf "Services" plain
EOF
}

options="←  Back
󰅟  Service status
󰐱  Deployments
󰢬  Latest deploy logs
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
    run_in_kitty "ECS Status - $AWS_PROFILE" "$(service_status_command)" return-on-success toggle "$RETURN_TO_ECS_COMMAND"
    ;;
  "󰐱  Deployments")
    run_in_kitty "ECS Deployments - $AWS_PROFILE" "$(deployments_command)" return-on-success toggle "$RETURN_TO_ECS_COMMAND"
    ;;
  "󰢬  Latest deploy logs")
    run_in_kitty "ECS Deploy Logs - $AWS_PROFILE" "$(deployment_logs_command)" return-on-success toggle "$RETURN_TO_ECS_COMMAND"
    ;;
  "󰑓  Service events")
    run_in_kitty "ECS Events - $AWS_PROFILE" "$(service_events_command)" return-on-success toggle "$RETURN_TO_ECS_COMMAND"
    ;;
  "󰐱  Running tasks")
    run_in_kitty "ECS Running Tasks - $AWS_PROFILE" "$(running_tasks_command)" return-on-success toggle "$RETURN_TO_ECS_COMMAND"
    ;;
  "  Stopped tasks")
    run_in_kitty "ECS Stopped Tasks - $AWS_PROFILE" "$(stopped_tasks_command)" return-on-success toggle "$RETURN_TO_ECS_COMMAND"
    ;;
  "󰌗  List clusters")
    run_in_kitty "ECS Clusters - $AWS_PROFILE" "$(list_clusters_command)" return-on-success toggle "$RETURN_TO_ECS_COMMAND"
    ;;
  "󰓾  List services")
    run_in_kitty "ECS Services - $AWS_PROFILE" "$(list_services_command)" return-on-success toggle "$RETURN_TO_ECS_COMMAND"
    ;;
  "")
    exit 0
    ;;
esac
