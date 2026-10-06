#!/usr/bin/env bash
set -euo pipefail
sleep 0.2
bash "$HOME/.config/quickshell/lockscreen/scripts/launch.sh" preview "${1:?Missing lockscreen}"
exec walker --provider menus:lockscreen
