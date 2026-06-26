#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/walker/scripts/menus/cloud/aws/common.sh"

[ -z "$AWS_PROFILE" ] && exit 0

options="󰨇  Workspaces
󰈹  Open workspace
󰅟  Workspace details"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="Amazon Grafana - $AWS_PROFILE")

choose_workspace() {
  local workspaces chosen

  if ! workspaces="$(aws_cli grafana list-workspaces | jq -r '.workspaces[] | "\(.name)  \(.id)"')"; then
    notify-send "Amazon Grafana" "Failed to list workspaces"
    exit 1
  fi

  [ -z "$workspaces" ] && notify-send "Amazon Grafana" "No workspaces found" && exit 0
  chosen="$(printf "%s\n" "$workspaces" | walker_menu "Grafana Workspace")"
  [ -z "$chosen" ] && exit 0
  echo "$chosen" | awk '{ print $NF }'
}

case "$chosen" in
  "󰨇  Workspaces")
    run_in_kitty "Grafana Workspaces - $AWS_PROFILE" "
aws_header 'Amazon Grafana workspaces'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) grafana list-workspaces \
| jq -r '.workspaces[] | \"\u001b[36m\(.name)\u001b[0m  id=\(.id)  status=\(.status)  endpoint=\(.endpoint // \"N/A\")\"' \
| aws_fzf 'Workspaces' plain
" close-on-success toggle
    ;;
  "󰈹  Open workspace")
    workspace_id="$(choose_workspace)"

    if ! endpoint="$(aws_cli grafana describe-workspace --workspace-id "$workspace_id" | jq -r '.workspace.endpoint // empty')"; then
      notify-send "Amazon Grafana" "Failed to get workspace endpoint"
      exit 1
    fi

    [ -z "$endpoint" ] && notify-send "Amazon Grafana" "Workspace has no endpoint" && exit 0
    xdg-open "https://$endpoint" >/dev/null 2>&1 &
    ;;
  "󰅟  Workspace details")
    workspace_id="$(choose_workspace)"
    quoted_workspace_id="$(shell_quote "$workspace_id")"

    run_in_kitty "Grafana Workspace - $AWS_PROFILE" "
aws_header 'Amazon Grafana workspace'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Workspace' $quoted_workspace_id
echo

$(aws_base) grafana describe-workspace --workspace-id $quoted_workspace_id | aws_json
" close-on-success toggle
    ;;
  "")
    exit 0
    ;;
esac
