# Desktop Bar Preview

This is a first-pass Quickshell bar preview.

Right-click a workspace to choose Numbers, Glyph, or Dots, or use Walker's
Style > Workspaces menu. Both selectors share the same saved preference.
The menu includes examples; the checkmark identifies the current selection.
The choice is saved in `workspace-style.json`. Selected workspace colors follow
the current theme's accent.

Calendar, Weather, and AI Usage dismiss on an outside click, not on pointer
movement or focus loss. A small native helper uses the same Hyprland focus-grab
protocol as the workspace popup, retaining the panels' GTK layouts and controls.
Sources and the licensed protocol XML are in `scripts/native/`; the shared
library is built into `~/.cache/desktop-bar-native`, never into the backup.
Build dependencies are `gcc`, `pkgconf`, `wayland`, and `gtk4`. The helper builds
automatically on first use; `bash scripts/build-panel-grab.sh` prebuilds it.
On unsupported systems or a failed build, panels remain open until closed
normally. No focus-loss fallback is used.

Bar tooltips follow the current theme's background and foreground colors.

Click GPU, CPU, or RAM to open the shared hardware popup. It refreshes every
two seconds while visible and closes on an outside click or Escape. CPU load,
cores, frequency and temperature, GPU usage, VRAM and power, and RAM/swap totals
are read locally. GPU telemetry uses `nvidia-smi`; temperatures use `sensors`.
Missing optional telemetry is shown as unavailable. No terminal is launched.

Volume and Mic open themed native PipeWire popups with live volume/gain sliders,
mute controls, and default output/input device selection. Volume also lists
playback applications with individual sliders and mute controls. Sliders adjust
up to 100% without changing existing higher values until moved. Moving the mouse
away does not dismiss either popup; outside clicks, Escape, or hiding the status
icons do. Long lists scroll within the available screen height. No settings
application is launched, and opening Mic does not start audio capture.

The keyboard icon and Walker's System > Keyboard menu share the configured
layout selector and follow changes made with Alt+Shift. Weather keeps the city's local temperature unit
as the main reading, with a smaller equivalent in the other unit alongside it.

Install Quickshell:

```sh
sudo pacman -S quickshell
```

Run the preview:

```sh
quickshell -c desktop-bar --daemonize
```

Toggle the bar:

```sh
~/.config/walker/scripts/actions/toggle/desktop-bar.sh
```

Stop the bar:

```sh
quickshell kill -c desktop-bar
```
