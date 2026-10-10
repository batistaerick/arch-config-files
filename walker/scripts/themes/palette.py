#!/usr/bin/env python3
"""Read the active theme palette and answer light/dark questions.

The theme directory holds a flat ``colors.toml`` (accent, foreground,
background, cursor, selection_*, color0-color15) and an optional
``light.mode`` marker.  ``light.mode`` is the single source of truth for
whether a theme is light; luminance helpers are for contrast decisions only.

Usage:
  palette.py get KEY...        print one value per line (empty if missing)
  palette.py is-light          exit 0 for light themes, 1 for dark themes
  palette.py fzf-colors        print an fzf --color value, or nothing
Set THEME_DIR (or pass --dir) to read a theme other than the current one.
"""

import argparse
import os
from pathlib import Path
import re
import sys
import tomllib

HEX_COLOR = re.compile(r"^#[0-9A-Fa-f]{6}$")


def current_dir():
    return Path(os.environ.get("THEME_DIR") or Path.home() / ".config/theme/current")


def load(directory=None):
    """Return the palette's valid hex colors; an empty dict if it is missing."""
    path = Path(directory or current_dir()) / "colors.toml"
    try:
        with path.open("rb") as source:
            data = tomllib.load(source)
    except (OSError, tomllib.TOMLDecodeError):
        return {}
    return {key: value for key, value in data.items()
            if isinstance(value, str) and HEX_COLOR.match(value)}


def is_light(directory=None):
    return (Path(directory or current_dir()) / "light.mode").exists()


def rgb(color):
    return tuple(int(color[index:index + 2], 16) for index in (1, 3, 5))


def luminance(color):
    channels = [value / 255 for value in rgb(color)]
    linear = [value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
              for value in channels]
    return sum(value * weight for value, weight in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(first, second):
    bright, dark = sorted((luminance(first), luminance(second)), reverse=True)
    return (bright + 0.05) / (dark + 0.05)


def fzf_colors(palette):
    """Map a palette onto fzf's color roles; empty when the palette is incomplete."""
    if not all(key in palette for key in ("foreground", "background", "accent")):
        return ""
    fg, bg, accent = palette["foreground"], palette["background"], palette["accent"]
    roles = {
        "fg": fg, "bg": bg, "hl": palette.get("color1", accent),
        "fg+": fg, "bg+": palette.get("color0", bg), "hl+": palette.get("color1", accent),
        "info": palette.get("color5", accent), "prompt": accent,
        "pointer": accent, "marker": palette.get("color2", accent),
        "spinner": palette.get("color3", accent), "header": palette.get("color6", accent),
        "border": accent,
    }
    return ",".join(f"{role}:{color}" for role, color in roles.items())


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dir", type=Path, help="theme directory (default: current theme)")
    commands = parser.add_subparsers(dest="command", required=True)
    get = commands.add_parser("get")
    get.add_argument("keys", nargs="+")
    commands.add_parser("is-light")
    commands.add_parser("fzf-colors")
    args = parser.parse_args(argv)

    if args.command == "is-light":
        return 0 if is_light(args.dir) else 1
    palette = load(args.dir)
    if args.command == "get":
        for key in args.keys:
            print(palette.get(key, ""))
    else:
        print(fzf_colors(palette))
    return 0


if __name__ == "__main__":
    sys.exit(main())
