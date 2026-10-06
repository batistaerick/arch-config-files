#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET


def keyboards():
    result = subprocess.run(['hyprctl', 'devices', '-j'], capture_output=True,
                            text=True, check=True, timeout=3)
    return json.loads(result.stdout).get('keyboards', [])


def options(keyboard):
    layouts = keyboard.get('layout', '').split(',')
    variants = keyboard.get('variant', '').split(',')
    try:
        registry = ET.parse('/usr/share/X11/xkb/rules/evdev.xml')
    except (OSError, ET.ParseError):
        registry = None
    entries = []
    for index, layout in enumerate(layouts):
        variant = variants[index] if index < len(variants) else ''
        label = f'{layout.upper()} ({variant})' if variant else layout.upper()
        if registry is not None:
            node = next((entry for entry in registry.findall('./layoutList/layout')
                         if entry.findtext('configItem/name') == layout), None)
            if node is not None:
                label = node.findtext('configItem/description') or label
                if variant:
                    item = next((entry for entry in node.findall('./variantList/variant')
                                 if entry.findtext('configItem/name') == variant), None)
                    if item is not None:
                        label = item.findtext('configItem/description') or label
        if (layout, variant) == ('us', 'intl'):
            label = 'English (US International)'
        entries.append({'index': index, 'label': label})
    return entries


def main():
    devices = keyboards()
    keyboard = next((entry for entry in devices if entry.get('main')),
                    devices[0] if devices else None)
    if keyboard is None:
        raise SystemExit('No keyboard found')
    entries = options(keyboard)
    if len(sys.argv) == 3 and sys.argv[1] == 'select':
        index = int(sys.argv[2])
        if index not in [entry['index'] for entry in entries]:
            raise SystemExit('Unknown keyboard layout')
        for device in devices:
            if (device.get('layout'), device.get('variant')) == (keyboard.get('layout'), keyboard.get('variant')):
                subprocess.run(['hyprctl', 'switchxkblayout', device['name'], str(index)],
                               check=True, capture_output=True, timeout=3)
    elif len(sys.argv) == 2 and sys.argv[1] == 'list':
        active = keyboard.get('active_layout_index', 0)
        for entry in entries:
            print(f"{entry['index']}\t{entry['label']}\t{int(entry['index'] == active)}")
    elif len(sys.argv) == 1:
        print(json.dumps({'layouts': entries, 'active': keyboard.get('active_layout_index', 0)}))
    else:
        raise SystemExit('Usage: keyboard-layout.py [list | select INDEX]')


if __name__ == '__main__':
    main()
