#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

if [ -z "$AWS_PROFILE" ]; then
  exit 0
fi

options="←  Back
󰉋  List buckets
  Search bucket by name"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="S3 - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "󰉋  List buckets")
    run_in_kitty "S3 Buckets - $AWS_PROFILE" "
aws_header 'S3 buckets'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) s3 ls \
| awk '{print \"\033[90m\" \$1 \" \" \$2 \"\033[0m  \033[36m\" \$3 \"\033[0m\"}' \
| aws_fzf 'Buckets'
"
    ;;

  "  Search bucket by name")
    word="$(ask_search_word)"

    if [ -z "$word" ]; then
      exit 0
    fi

    quoted_word="$(shell_quote "$word")"

    run_in_kitty "S3 Search - $AWS_PROFILE" "
aws_header 'S3 bucket search'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Search' $quoted_word
echo

$(aws_base) s3 ls \
| grep -i -- $quoted_word \
| awk '{print \"\033[90m\" \$1 \" \" \$2 \"\033[0m  \033[36m\" \$3 \"\033[0m\"}' \
| aws_fzf 'Buckets'
"
    ;;

  "")
    exit 0
    ;;
esac
