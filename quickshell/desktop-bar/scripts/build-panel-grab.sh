#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")" && pwd)"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/desktop-bar-native"
mkdir -p "$cache"
exec 9>"$cache/build.lock"
flock 9
library="$cache/panel-grab.so"
if [[ ! -f "$library" || "$root/native/panel-grab.c" -nt "$library" || "$root/native/hyprland-focus-grab-v1.xml" -nt "$library" || "$0" -nt "$library" ]]; then
    build="$(mktemp -d "$cache/build.XXXXXX")"
    trap 'find "$build" -depth -delete' EXIT
    wayland-scanner client-header "$root/native/hyprland-focus-grab-v1.xml" "$build/focus-grab.h"
    wayland-scanner private-code "$root/native/hyprland-focus-grab-v1.xml" "$build/focus-grab.c"
    read -r -a flags <<< "$(pkg-config --cflags --libs gtk4 wayland-client)"
    cc -shared -fPIC -O2 -Wall -Wextra -Werror -I"$build" \
        "$root/native/panel-grab.c" "$build/focus-grab.c" "${flags[@]}" -o "$build/panel-grab.so"
    mv "$build/panel-grab.so" "$library"
fi
printf '%s\n' "$library"
