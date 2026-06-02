#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

[ -z "$AWS_PROFILE" ] && exit 0

choose_iam_user() {
  local users chosen

  if ! users="$(aws_cli iam list-users | jq -r '.Users[].UserName')"; then
    notify-send "IAM" "Failed to list users"
    exit 1
  fi

  [ -z "$users" ] && notify-send "IAM" "No users found" && exit 0
  chosen="$(printf "%s\n" "$users" | wofi_menu "IAM User")"
  [ -z "$chosen" ] && exit 0
  echo "$chosen"
}

options="←  Back
󰀄  Account summary
󰀄  Users
󰌾  Roles
󰒃  Policies
󰘦  Groups
󰌆  User access keys"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="IAM - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "󰀄  Account summary")
    run_in_kitty "IAM Summary - $AWS_PROFILE" "
aws_header 'IAM account summary'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) iam get-account-summary \
| jq -r '.SummaryMap | to_entries[] | \"\u001b[36m\(.key)\u001b[0m  \(.value)\"'
" close-on-key toggle
    ;;
  "󰀄  Users")
    run_in_kitty "IAM Users - $AWS_PROFILE" "
aws_header 'IAM users'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) iam list-users \
| jq -r '.Users[] | \"\u001b[36m\(.UserName)\u001b[0m  id=\(.UserId)  created=\(.CreateDate)  path=\(.Path)\"' \
| aws_fzf 'Users' plain
" close-on-success toggle
    ;;
  "󰌾  Roles")
    run_in_kitty "IAM Roles - $AWS_PROFILE" "
aws_header 'IAM roles'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) iam list-roles \
| jq -r '.Roles[] | \"\u001b[36m\(.RoleName)\u001b[0m  id=\(.RoleId)  created=\(.CreateDate)  path=\(.Path)\"' \
| aws_fzf 'Roles' plain
" close-on-success toggle
    ;;
  "󰒃  Policies")
    run_in_kitty "IAM Policies - $AWS_PROFILE" "
aws_header 'IAM customer managed policies'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) iam list-policies --scope Local \
| jq -r '.Policies[] | \"\u001b[36m\(.PolicyName)\u001b[0m  arn=\(.Arn)  attachments=\(.AttachmentCount)  updated=\(.UpdateDate)\"' \
| aws_fzf 'Policies' plain
" close-on-success toggle
    ;;
  "󰘦  Groups")
    run_in_kitty "IAM Groups - $AWS_PROFILE" "
aws_header 'IAM groups'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) iam list-groups \
| jq -r '.Groups[] | \"\u001b[36m\(.GroupName)\u001b[0m  id=\(.GroupId)  created=\(.CreateDate)  path=\(.Path)\"' \
| aws_fzf 'Groups' plain
" close-on-success toggle
    ;;
  "󰌆  User access keys")
    user="$(choose_iam_user)"
    quoted_user="$(shell_quote "$user")"

    run_in_kitty "IAM Access Keys - $AWS_PROFILE" "
aws_header 'IAM access keys'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'User' $quoted_user
echo

$(aws_base) iam list-access-keys --user-name $quoted_user \
| jq -r '.AccessKeyMetadata[] | \"\u001b[36m\(.AccessKeyId)\u001b[0m  status=\(.Status)  created=\(.CreateDate)\"' \
| aws_fzf 'Access keys' plain
" close-on-success toggle
    ;;
  "")
    exit 0
    ;;
esac
