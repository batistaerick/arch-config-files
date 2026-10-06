#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import shutil
import sys
import xml.etree.ElementTree as ET

STATE = Path.home() / '.config/hypr/keyboard-layouts.lua'


def catalog():
    registry = ET.parse('/usr/share/X11/xkb/rules/evdev.xml')
    entries = []
    for node in registry.findall('./layoutList/layout'):
        layout = node.findtext('configItem/name')
        if not layout:
            continue
        entries.append({'layout': layout, 'variant': '',
                        'label': node.findtext('configItem/description') or layout})
        for variant in node.findall('./variantList/variant'):
            name = variant.findtext('configItem/name')
            if name:
                entries.append({'layout': layout, 'variant': name,
                                'label': variant.findtext('configItem/description') or name})
    return entries


def layout_pairs(keyboard):
    layouts = keyboard.get('layout', '').split(',')
    variants = keyboard.get('variant', '').split(',')
    return [(layout, variants[index] if index < len(variants) else '')
            for index, layout in enumerate(layouts) if layout]


def append_layout(keyboard, layout, variant, available):
    if not any((entry['layout'], entry['variant']) == (layout, variant) for entry in available):
        raise ValueError('Unknown keyboard layout')
    pairs = layout_pairs(keyboard)
    if (layout, variant) in pairs:
        raise ValueError('This layout is already added')
    if len(pairs) >= 4:
        raise ValueError('A maximum of four layouts can be active at once')
    pairs.append((layout, variant))
    layout_string = ','.join(pair[0] for pair in pairs)
    variant_string = ','.join(pair[1] for pair in pairs)
    if shutil.which('xkbcli'):
        result = subprocess.run(['xkbcli', 'compile-keymap', '--test', '--layout', layout_string,
                                 '--variant', variant_string, '--options', keyboard.get('options', '')],
                                capture_output=True, timeout=5)
        if result.returncode:
            raise ValueError('This keyboard layout could not be loaded')
    previous = STATE.read_text() if STATE.exists() else None
    content = 'return { layout = %s, variant = %s }\n' % (
        json.dumps(layout_string), json.dumps(variant_string))
    temporary = STATE.with_suffix('.tmp')
    temporary.write_text(content)
    os.replace(temporary, STATE)
    try:
        subprocess.run(['hyprctl', 'reload'], check=True, capture_output=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        if previous is None:
            STATE.unlink(missing_ok=True)
        else:
            temporary.write_text(previous)
            os.replace(temporary, STATE)
        subprocess.run(['hyprctl', 'reload'], capture_output=True, timeout=10)
        raise


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
    if sys.argv[1:] == ['catalog']:
        print(json.dumps({'layouts': catalog()}))
        return
    devices = keyboards()
    keyboard = next((entry for entry in devices if entry.get('main')),
                    devices[0] if devices else None)
    if keyboard is None:
        raise SystemExit('No keyboard found')
    entries = options(keyboard)
    if len(sys.argv) == 4 and sys.argv[1] == 'add':
        append_layout(keyboard, sys.argv[2], sys.argv[3], catalog())
        print(json.dumps({'ok': True}))
    elif len(sys.argv) == 3 and sys.argv[1] == 'select':
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
        raise ValueError('Usage: keyboard-layout.py [list | catalog | select INDEX | add LAYOUT VARIANT]')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, ET.ParseError, subprocess.SubprocessError) as error:
        print(json.dumps({'error': str(error)}))
        sys.exit(1)
