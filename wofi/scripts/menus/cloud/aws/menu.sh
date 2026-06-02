#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

choose_profile() {
  local include_back="$1"
  local back_option=()

  if [ "$include_back" = "with-back" ]; then
    back_option=("←  Back")
  fi

  wofi_menu "AWS Profile" \
    "${back_option[@]}" \
    "Engineering-Dev-394540956281" \
    "Engineering-Prod-576249115295" \
    "default"
}

if [ "$1" = "--choose-profile-only" ]; then
  AWS_PROFILE="$(choose_profile)"

  if [ "$AWS_PROFILE" = "←  Back" ]; then
    exit 0
  fi

  printf "%s\n" "$AWS_PROFILE"
  exit 0
fi

AWS_PROFILE="${1:-$(choose_profile with-back)}"

case "$AWS_PROFILE" in
  "←  Back")
    "$MENUS_DIR/cloud.sh"
    exit 0
    ;;
  "")
    exit 0
    ;;
esac

options="←  Back
󰒋  SSO Login
󰅟  Check Auth
󰃷  CloudWatch
󰡨  ECS
󰓟  S3
  Aurora / RDS
  ECR"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="AWS - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/cloud.sh"
    ;;

  "󰒋  SSO Login")
    run_in_kitty "AWS SSO - $AWS_PROFILE" "
aws_header 'AWS SSO login'
aws_kv 'Profile' '$AWS_PROFILE'
aws_success 'Opening AWS SSO login...'
echo
$(aws_base) sso login
"
    ;;

  "󰅟  Check Auth")
    run_in_kitty "AWS Auth - $AWS_PROFILE" "
aws_header 'AWS auth'
aws_kv 'Profile' '$AWS_PROFILE'
aws_success 'Checking AWS auth...'
echo
$(aws_base) sts get-caller-identity \
| jq -C .
"
    ;;

  "󰃷  CloudWatch")
    "$AWS_MENUS_DIR/cloudwatch.sh" "$AWS_PROFILE"
    ;;

  "󰡨  ECS")
    "$AWS_MENUS_DIR/ecs.sh" "$AWS_PROFILE"
    ;;

  "󰓟  S3")
    "$AWS_MENUS_DIR/s3.sh" "$AWS_PROFILE"
    ;;

  "  Aurora / RDS")
    "$AWS_MENUS_DIR/rds.sh" "$AWS_PROFILE"
    ;;

  "  ECR")
    "$AWS_MENUS_DIR/ecr.sh" "$AWS_PROFILE"
    ;;

  "")
    exit 0
    ;;
esac
