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

The keyboard icon opens the configured layout selector and follows layout
changes made with Alt+Shift. Weather keeps the city's local temperature unit
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
