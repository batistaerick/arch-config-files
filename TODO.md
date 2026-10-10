# Before Publishing

See [PUBLISHING.md](PUBLISHING.md): split the personal overlay from the distro,
move large media out of Git history, finish licensing and artwork clearance,
scan history for secrets, and add a diagnostics action.

# Display Layout

Deferred until a second physical monitor is connected for testing:

- Add side-by-side and stacked layouts with explicit display order.
- Center the secondary display against the larger one, using logical dimensions.
- Preserve display resolution, refresh rate, scale, and color settings.
- Preview layout changes with confirmation and automatic rollback.
- Verify layouts and persistent primary selection with both monitors connected.
- Verify OBS full-screen capture follows the selected primary display. Its
  Wayland portal permission currently keeps the previously selected monitor;
  do not silently claim this follows the bar's primary setting.

Primary selection is already implemented in the Display panel and persists
in the machine-local `hypr/primary-display` file.
