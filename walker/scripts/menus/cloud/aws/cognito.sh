#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/walker/scripts/menus/cloud/aws/common.sh"

[ -z "$AWS_PROFILE" ] && exit 0

choose_user_pool() {
  local pools chosen

  if ! pools="$(aws_cli cognito-idp list-user-pools --max-results 60 | jq -r '.UserPools[] | "\(.Name)  \(.Id)"')"; then
    notify-send "Cognito" "Failed to list user pools"
    exit 1
  fi

  [ -z "$pools" ] && notify-send "Cognito" "No user pools found" && exit 0
  chosen="$(printf "%s\n" "$pools" | walker_menu "User Pool")"
  [ -z "$chosen" ] && exit 0
  echo "$chosen" | awk '{ print $NF }'
}

options="󰟵  User pools
󰀄  Identity pools
󰘦  App clients
󰅟  User pool details"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="Cognito - $AWS_PROFILE")

case "$chosen" in
  "󰟵  User pools")
    run_in_kitty "Cognito User Pools - $AWS_PROFILE" "
aws_header 'Cognito user pools'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) cognito-idp list-user-pools --max-results 60 \
| jq -r '.UserPools[] | \"\u001b[36m\(.Name)\u001b[0m  id=\(.Id)  status=\(.Status // \"N/A\")  created=\(.CreationDate)\"' \
| aws_fzf 'User pools' plain
" close-on-success toggle
    ;;
  "󰀄  Identity pools")
    run_in_kitty "Cognito Identity Pools - $AWS_PROFILE" "
aws_header 'Cognito identity pools'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) cognito-identity list-identity-pools --max-results 60 \
| jq -r '.IdentityPools[] | \"\u001b[36m\(.IdentityPoolName)\u001b[0m  id=\(.IdentityPoolId)\"' \
| aws_fzf 'Identity pools' plain
" close-on-success toggle
    ;;
  "󰘦  App clients")
    pool_id="$(choose_user_pool)"
    quoted_pool_id="$(shell_quote "$pool_id")"

    run_in_kitty "Cognito App Clients - $AWS_PROFILE" "
aws_header 'Cognito app clients'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'User pool' $quoted_pool_id
echo

$(aws_base) cognito-idp list-user-pool-clients --user-pool-id $quoted_pool_id --max-results 60 \
| jq -r '.UserPoolClients[] | \"\u001b[36m\(.ClientName)\u001b[0m  id=\(.ClientId)\"' \
| aws_fzf 'App clients' plain
" close-on-success toggle
    ;;
  "󰅟  User pool details")
    pool_id="$(choose_user_pool)"
    quoted_pool_id="$(shell_quote "$pool_id")"

    run_in_kitty "Cognito User Pool - $AWS_PROFILE" "
aws_header 'Cognito user pool details'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'User pool' $quoted_pool_id
echo

$(aws_base) cognito-idp describe-user-pool --user-pool-id $quoted_pool_id | aws_json
" close-on-success toggle
    ;;
  "")
    exit 0
    ;;
esac
