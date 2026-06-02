#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

if [ -z "$AWS_PROFILE" ]; then
  exit 0
fi

choose_ecr_repository() {
  local repositories
  local chosen

  if ! repositories="$(aws_cli ecr describe-repositories | jq -r '.repositories[].repositoryName')"; then
    notify-send "ECR" "Failed to list repositories for $AWS_PROFILE"
    exit 1
  fi

  if [ -z "$repositories" ]; then
    notify-send "ECR" "No repositories found for $AWS_PROFILE"
    exit 0
  fi

  chosen="$(printf "%s\n" "$repositories" | wofi_menu "ECR Repository")"

  if [ -z "$chosen" ]; then
    exit 0
  fi

  echo "$chosen"
}

options="←  Back
  List repositories
  Search repository
󰁫  Latest image tags"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="ECR - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "  List repositories")
    run_in_kitty "ECR Repositories - $AWS_PROFILE" "
aws_header 'ECR repositories'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) ecr describe-repositories \
| jq -r '.repositories[] | \"\u001b[36m\(.repositoryName)\u001b[0m  \u001b[90m\(.repositoryUri)\u001b[0m\"' \
| aws_fzf 'Repositories'
" close-on-success
    ;;

  "  Search repository")
    word="$(ask_search_word)"

    if [ -z "$word" ]; then
      exit 0
    fi

    quoted_word="$(shell_quote "$word")"

    run_in_kitty "ECR Search - $AWS_PROFILE" "
aws_header 'ECR repository search'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Search' $quoted_word
echo

$(aws_base) ecr describe-repositories \
| jq -r '.repositories[] | \"\u001b[36m\(.repositoryName)\u001b[0m  \u001b[90m\(.repositoryUri)\u001b[0m\"' \
| grep -i -- $quoted_word \
| aws_fzf 'Repositories'
" close-on-success
    ;;

  "󰁫  Latest image tags")
    repo="$(choose_ecr_repository)"

    quoted_repo="$(shell_quote "$repo")"

    run_in_kitty "ECR Images - $AWS_PROFILE" "
aws_header 'Latest ECR images'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Repository' $quoted_repo
echo

$(aws_base) ecr describe-images \
  --repository-name $quoted_repo \
  --query 'reverse(sort_by(imageDetails,& imagePushedAt))[:20]' \
| jq -r '.[] | \"\u001b[90m\(.imagePushedAt)\u001b[0m  \u001b[36mtags=\(.imageTags // [])\u001b[0m  digest=\(.imageDigest)\"' \
| aws_fzf 'Images'
" close-on-success
    ;;

  "")
    exit 0
    ;;
esac
