# Desktop Bar Preview

This is a first-pass Quickshell bar preview.

Right-click a workspace to choose Numbers, Glyph, or Dots, or use Walker's
Style > Workspaces menu. Both selectors share the same saved preference.
The menu includes examples; the checkmark identifies the current selection.
The choice is saved in `workspace-style.json`. Selected workspace colors follow
the current theme's accent.

Calendar, Weather, and AI Usage use native Quickshell popups and dismiss on an
outside click or Escape, not pointer movement or focus loss. Calendar and Weather
stay top-center; AI Usage stays on the right. Calendar retains its fixed six-row
grid, bottom navigation, year progress, and Left/Right/Up/Down/bracket/T keys.
AI Usage retains the existing backend/cache, refresh-on-open, manual refresh,
and five-minute updates while open. Weather retains the 15-minute refresh,
debounced city search, country-based units, and smaller alternate temperature.
City overrides last only until the popup closes; the bar's default is unchanged.
Escape cancels city search first, then closes Weather. Buttons support Tab/Enter.

The previous GTK panels and their click-outside helper remain available as
fallback scripts, but bar clicks no longer launch them. The helper's licensed
sources are in `scripts/native/`, with builds cached in
`~/.cache/desktop-bar-native` (dependencies: `gcc`, `pkgconf`, `wayland`, `gtk4`).

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
