#!/usr/bin/env python3
"""Choose palette colors with readable contrast on Walker's row highlight."""

import json
from pathlib import Path
import sys
import tomllib


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


def selection_colors(palette, light=False):
    base = palette['background']
    overlay = palette.get('color8', palette.get('color0', base))
    alpha = 0.22 if light else 0.26
    background = '#' + ''.join(f'{round(a * alpha + b * (1 - alpha)):02x}'
                              for a, b in zip(rgb(overlay), rgb(base)))
    candidates = [palette['foreground'], base, *palette.values()]
    candidates = [color for color in candidates
                  if isinstance(color, str) and len(color) == 7 and color.startswith('#')]

    def readable(preferred):
        for color in [preferred, *candidates]:
            if contrast(color, background) >= 4.5:
                return color
        return max(candidates, key=lambda color: contrast(color, background))

    return {'background': background,
            'foreground': readable(palette.get('selection_foreground', base)),
            'current': readable(palette['accent'])}


if __name__ == '__main__':
    directory = Path(sys.argv[1])
    with (directory / 'colors.toml').open('rb') as source:
        palette = tomllib.load(source)
    print(json.dumps(selection_colors(palette, (directory / 'light.mode').exists())))
