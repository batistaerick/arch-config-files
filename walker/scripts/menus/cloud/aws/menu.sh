#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/aws/common.sh"

choose_profile() {
  walker_menu "AWS Profile" \
    "Development" \
    "Production"
}

resolve_profile() {
  case "$1" in
    "Development")
      echo "Engineering-Dev-394540956281"
      ;;
    "Production")
      echo "Engineering-Prod-576249115295"
      ;;
    *)
      echo "$1"
      ;;
  esac
}

if [ "$1" = "--choose-profile-only" ]; then
  AWS_PROFILE="$(resolve_profile "$(choose_profile)")"
  printf "%s\n" "$AWS_PROFILE"
  exit 0
fi

AWS_PROFILE="${1:-$(resolve_profile "$(choose_profile)")}"

case "$AWS_PROFILE" in
  "")
    exit 0
    ;;
esac

case "${2:-}" in
  --sso-login)
    run_in_kitty "AWS SSO - $AWS_PROFILE" "
aws_header 'AWS SSO login'
aws_kv 'Profile' '$AWS_PROFILE'
aws_success 'Opening AWS SSO login...'
echo
$(aws_base) sso login
" close-on-success
    exit 0
    ;;
  --check-auth)
    run_in_kitty "AWS Auth - $AWS_PROFILE" "
aws_header 'AWS auth'
aws_kv 'Profile' '$AWS_PROFILE'
aws_success 'Checking AWS auth...'
echo
$(aws_base) sts get-caller-identity \
| jq -r '
  \"\u001b[34mUserId:\u001b[0m  \(.UserId)\",
  \"\u001b[34mAccount:\u001b[0m \(.Account)\",
  \"\u001b[34mArn:\u001b[0m     \(.Arn)\"
'
" close-on-key toggle
    exit 0
    ;;
esac

options="󰒋  SSO Login
󰅟  Check Auth
󰃷  CloudWatch
󰡨  ECS
󰓟  S3
  Aurora / RDS
  ECR
󰨇  Amazon Grafana
󰘦  Cognito
  DocumentDB
󰊕  Lambda
󰅧  CloudFront
󰌢  Lightsail
󰍹  EC2
󰑃  Route 53
󰖟  VPC
󰒃  IAM"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="AWS - $AWS_PROFILE")

case "$chosen" in

  "󰒋  SSO Login")
    run_in_kitty "AWS SSO - $AWS_PROFILE" "
aws_header 'AWS SSO login'
aws_kv 'Profile' '$AWS_PROFILE'
aws_success 'Opening AWS SSO login...'
echo
$(aws_base) sso login
" close-on-success
    ;;

  "󰅟  Check Auth")
    run_in_kitty "AWS Auth - $AWS_PROFILE" "
aws_header 'AWS auth'
aws_kv 'Profile' '$AWS_PROFILE'
aws_success 'Checking AWS auth...'
echo
$(aws_base) sts get-caller-identity \
| jq -r '
  \"\u001b[34mUserId:\u001b[0m  \(.UserId)\",
  \"\u001b[34mAccount:\u001b[0m \(.Account)\",
  \"\u001b[34mArn:\u001b[0m     \(.Arn)\"
'
" close-on-key toggle
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

  "󰨇  Amazon Grafana")
    "$AWS_MENUS_DIR/grafana.sh" "$AWS_PROFILE"
    ;;

  "󰘦  Cognito")
    "$AWS_MENUS_DIR/cognito.sh" "$AWS_PROFILE"
    ;;

  "  DocumentDB")
    "$AWS_MENUS_DIR/docdb.sh" "$AWS_PROFILE"
    ;;

  "󰊕  Lambda")
    "$AWS_MENUS_DIR/lambda.sh" "$AWS_PROFILE"
    ;;

  "󰅧  CloudFront")
    "$AWS_MENUS_DIR/cloudfront.sh" "$AWS_PROFILE"
    ;;

  "󰌢  Lightsail")
    "$AWS_MENUS_DIR/lightsail.sh" "$AWS_PROFILE"
    ;;

  "󰍹  EC2")
    "$AWS_MENUS_DIR/ec2.sh" "$AWS_PROFILE"
    ;;

  "󰑃  Route 53")
    "$AWS_MENUS_DIR/route53.sh" "$AWS_PROFILE"
    ;;

  "󰖟  VPC")
    "$AWS_MENUS_DIR/vpc.sh" "$AWS_PROFILE"
    ;;

  "󰒃  IAM")
    "$AWS_MENUS_DIR/iam.sh" "$AWS_PROFILE"
    ;;

  "")
    exit 0
    ;;
esac
