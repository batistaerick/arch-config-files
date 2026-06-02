#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

[ -z "$AWS_PROFILE" ] && exit 0

options="←  Back
󰍹  Instances
󰒋  Security groups
󰋊  Volumes
󰓦  Elastic IPs
󰅟  Instance status checks"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="EC2 - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "󰍹  Instances")
    run_in_kitty "EC2 Instances - $AWS_PROFILE" "
aws_header 'EC2 instances'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) ec2 describe-instances \
| jq -r '.Reservations[].Instances[] | \"\u001b[36m\((.Tags // [] | map(select(.Key == \"Name\"))[0].Value) // \"<no-name>\")\u001b[0m  id=\(.InstanceId)  state=\(.State.Name)  type=\(.InstanceType)  private=\(.PrivateIpAddress // \"N/A\")  public=\(.PublicIpAddress // \"N/A\")\"' \
| aws_fzf 'Instances' plain
" close-on-success toggle
    ;;
  "󰒋  Security groups")
    run_in_kitty "EC2 Security Groups - $AWS_PROFILE" "
aws_header 'EC2 security groups'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) ec2 describe-security-groups \
| jq -r '.SecurityGroups[] | \"\u001b[36m\(.GroupName)\u001b[0m  id=\(.GroupId)  vpc=\(.VpcId // \"classic\")  inbound=\(.IpPermissions | length)  outbound=\(.IpPermissionsEgress | length)\"' \
| aws_fzf 'Security groups' plain
" close-on-success toggle
    ;;
  "󰋊  Volumes")
    run_in_kitty "EC2 Volumes - $AWS_PROFILE" "
aws_header 'EC2 volumes'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) ec2 describe-volumes \
| jq -r '.Volumes[] | \"\u001b[36m\(.VolumeId)\u001b[0m  state=\(.State)  size=\(.Size)GiB  type=\(.VolumeType)  attached=\([.Attachments[].InstanceId] | join(\",\"))\"' \
| aws_fzf 'Volumes' plain
" close-on-success toggle
    ;;
  "󰓦  Elastic IPs")
    run_in_kitty "EC2 Elastic IPs - $AWS_PROFILE" "
aws_header 'EC2 Elastic IPs'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) ec2 describe-addresses \
| jq -r '.Addresses[] | \"\u001b[36m\(.PublicIp)\u001b[0m  allocation=\(.AllocationId // \"N/A\")  instance=\(.InstanceId // \"N/A\")  private=\(.PrivateIpAddress // \"N/A\")\"' \
| aws_fzf 'Elastic IPs' plain
" close-on-success toggle
    ;;
  "󰅟  Instance status checks")
    run_in_kitty "EC2 Status - $AWS_PROFILE" "
aws_header 'EC2 instance status checks'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) ec2 describe-instance-status --include-all-instances \
| jq -r '.InstanceStatuses[] | \"\u001b[36m\(.InstanceId)\u001b[0m  state=\(.InstanceState.Name)  system=\(.SystemStatus.Status)  instance=\(.InstanceStatus.Status)  az=\(.AvailabilityZone)\"' \
| aws_fzf 'Status checks' plain
" close-on-success toggle
    ;;
  "")
    exit 0
    ;;
esac
