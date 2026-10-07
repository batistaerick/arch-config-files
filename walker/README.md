# Walker

The launcher uses the current theme and Hyprland's blur settings.
`bin/walker` disables GTK's background-effects protocol only for Walker, allowing
the compositor's layer blur rule to apply. Other GTK applications are unchanged.

Install the launcher shim with:

```sh
mkdir -p ~/.local/bin
ln -s ../../.config/walker/bin/walker ~/.local/bin/walker
```

Keep `~/.local/bin` ahead of `/usr/bin` in PATH. The backup repository includes
the corresponding symlink under `HOME_FILES/.local/bin/walker`.
