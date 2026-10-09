#!/usr/bin/env bash

set -euo pipefail

if quickshell list --all 2>/dev/null | grep -q 'Config path: .*/quickshell/desktop-bar/shell.qml'; then
  quickshell ipc -c desktop-bar call -- bar visibility
else
  quickshell -c desktop-bar --daemonize
fi
