"""Shared panel colors with live palette reload and readable light-theme controls."""

from pathlib import Path
import re
import tomllib

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, GLib, Gtk

PALETTE = Path.home() / ".config/theme/current/colors.toml"


def panel_colors():
    try:
        palette = tomllib.loads(PALETTE.read_text())
    except (OSError, ValueError):
        palette = {}

    def color(key, fallback):
        value = palette.get(key, "")
        return value if re.fullmatch(r"#[0-9a-fA-F]{6}", str(value)) else fallback

    light = palette.get("mode") == "light"
    foreground = color("foreground", "#20202c" if light else "#cdd6f4")
    background = color("background", "#f5f5fa" if light else "#181824")

    def rgba(value, alpha):
        rgb = [int(value[index:index+2], 16) for index in (1, 3, 5)]
        return f"rgba({rgb[0]}, {rgb[1]}, {rgb[2]}, {alpha})"

    return {
        "light": light, "foreground": foreground,
        "background": rgba(background, 0.94),
        "accent": color("accent", foreground),
        "muted": rgba(foreground, 0.72), "faint": rgba(foreground, 0.58),
        "dim": rgba(foreground, 0.32), "surface": rgba(foreground, 0.08),
        "hover": rgba(foreground, 0.16), "track": rgba(foreground, 0.12),
        "selection_text": background,
    }


def install_panel_css(css):
    """Replace the panels' original color tokens, preserving their layout CSS."""
    provider = Gtk.CssProvider()
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
    )
    previous = None

    def reload():
        nonlocal previous
        colors = panel_colors()
        if colors != previous:
            previous = colors
            Adw.StyleManager.get_default().set_color_scheme(
                Adw.ColorScheme.FORCE_LIGHT if colors["light"] else Adw.ColorScheme.FORCE_DARK,
            )
            tokens = {
                "{{accent}}": colors["accent"],
                "rgba(24, 24, 36, 0.94)": colors["background"],
                "rgba(205, 214, 244, 0.72)": colors["muted"],
                "rgba(205, 214, 244, 0.58)": colors["faint"],
                "rgba(205, 214, 244, 0.52)": colors["faint"],
                "rgba(205, 214, 244, 0.32)": colors["dim"],
                "rgba(205, 214, 244, 0.08)": colors["surface"],
                "rgba(205, 214, 244, 0.16)": colors["hover"],
                "rgba(205, 214, 244, 0.12)": colors["track"],
                "rgba(255, 255, 255, 0.12)": colors["track"],
                "#cdd6f4": colors["foreground"], "#ffffff": colors["foreground"],
                "#11111b": colors["selection_text"],
            }
            themed = re.sub("|".join(re.escape(token) for token in tokens),
                            lambda match: tokens[match.group()], css)
            provider.load_from_data(themed.encode())
        return True

    reload()
    GLib.timeout_add_seconds(2, reload)
    return provider
