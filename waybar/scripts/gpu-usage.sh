#!/usr/bin/env bash

set -euo pipefail

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

if ! command -v nvidia-smi >/dev/null 2>&1; then
  printf '{"text":"󰢮 <span size='\''small'\''>--</span>","tooltip":"GPU: nvidia-smi is not installed","class":"unavailable"}\n'
  exit 0
fi

query="$(
  {
    nvidia-smi \
    --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,name \
    --format=csv,noheader,nounits 2>/dev/null |
      head -n 1
  } || true
)"

if [ -z "$query" ]; then
  printf '{"text":"󰢮 <span size='\''small'\''>--</span>","tooltip":"GPU: NVIDIA driver unavailable","class":"unavailable"}\n'
  exit 0
fi

IFS=',' read -r util mem_used mem_total temp name <<< "$query"

util="${util//[[:space:]]/}"
mem_used="${mem_used//[[:space:]]/}"
mem_total="${mem_total//[[:space:]]/}"
temp="${temp//[[:space:]]/}"

if [[ ! "$util" =~ ^[0-9]+$ ]]; then
  printf '{"text":"󰢮 <span size='\''small'\''>--</span>","tooltip":"GPU: NVIDIA driver unavailable","class":"unavailable"}\n'
  exit 0
fi

name="${name#"${name%%[![:space:]]*}"}"
name="${name%"${name##*[![:space:]]}"}"

tooltip="$(json_escape "GPU: $name
Usage: ${util}%
Memory: ${mem_used} MiB / ${mem_total} MiB
Temperature: ${temp}°C")"

printf '{"text":"󰢮 <span size='\''small'\''>%s%%</span>","tooltip":"%s","class":"active"}\n' "$util" "$tooltip"
