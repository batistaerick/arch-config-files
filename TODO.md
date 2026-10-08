# Display Layout

Deferred until a second physical monitor is connected for testing:

- Add side-by-side and stacked layouts with explicit display order.
- Center the secondary display against the larger one, using logical dimensions.
- Preserve display resolution, refresh rate, scale, and color settings.
- Preview layout changes with confirmation and automatic rollback.
- Verify layouts and persistent primary selection with both monitors connected.

Primary selection is already implemented in the Display panel and persists
in the machine-local `hypr/primary-display` file.
