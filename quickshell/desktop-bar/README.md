# Desktop Bar Preview

This is a first-pass Quickshell bar preview.

Right-click a workspace to choose Numbers, Glyph, or Dots, or use Walker's
Style > Workspaces menu. Both selectors share the same saved preference.
The menu includes examples; the checkmark identifies the current selection.
The choice is saved in `workspace-style.json`. Selected workspace colors follow
the current theme's accent.

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
