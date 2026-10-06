"""Click-outside dismissal using Hyprland's surface whitelist, not focus loss."""
import ctypes
from pathlib import Path
import subprocess
import sys

from gi.repository import GLib

CALLBACK = ctypes.CFUNCTYPE(None, ctypes.c_void_p)


def dismiss_on_outside_click(window):
    try:
        path = subprocess.check_output(
            ['bash', str(Path(__file__).with_name('build-panel-grab.sh'))],
            text=True, timeout=30,
        ).strip()
        native = ctypes.CDLL(path)
        native.panel_grab_create.argtypes = [ctypes.c_void_p, CALLBACK, ctypes.c_void_p]
        native.panel_grab_create.restype = ctypes.c_void_p
        native.panel_grab_destroy.argtypes = [ctypes.c_void_p]
        native.panel_grab_destroy.restype = None
    except (OSError, subprocess.SubprocessError) as error:
        print(f'Click-outside dismissal unavailable: {error}', file=sys.stderr)
        return

    state = {'grab': None, 'setup': 0, 'dismiss': 0, 'closed': False}

    def dismiss():
        state['dismiss'] = 0
        if not state['closed']:
            window.close()
        return GLib.SOURCE_REMOVE

    @CALLBACK
    def cleared(_data):
        # Defer destruction until the Wayland event callback has returned.
        if not state['closed'] and not state['dismiss']:
            state['dismiss'] = GLib.idle_add(dismiss)

    def release():
        for key in ('setup', 'dismiss'):
            if state[key]:
                GLib.source_remove(state[key])
                state[key] = 0
        if state['grab']:
            native.panel_grab_destroy(state['grab'])
            state['grab'] = None

    def acquire():
        state['setup'] = 0
        if state['closed'] or not window.get_mapped():
            return GLib.SOURCE_REMOVE
        surface = window.get_surface()
        state['grab'] = native.panel_grab_create(hash(surface), cleared, None)
        if not state['grab']:
            print('Click-outside dismissal requires Hyprland on Wayland.', file=sys.stderr)
        return GLib.SOURCE_REMOVE

    def mapped(_window):
        release()
        state['setup'] = GLib.timeout_add(100, acquire)

    def closed(_window):
        state['closed'] = True
        release()
        return False

    window.connect('map', mapped)
    window.connect('unmap', lambda _: release())
    window.connect('close-request', closed)
    # Keep the native callback alive for the entire window lifetime.
    window._outside_click_callback = cleared
    if window.get_mapped():
        mapped(window)
