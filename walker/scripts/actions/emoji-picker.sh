#!/usr/bin/env bash
set -euo pipefail
if pgrep -f '^quickshell .*\-c emoji-picker( |$)' >/dev/null; then
    quickshell kill -c emoji-picker
else
    quickshell -n -c emoji-picker --daemonize
fi
