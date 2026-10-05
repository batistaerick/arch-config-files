# Desktop Bar Preview

This is a first-pass Quickshell bar preview.

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
