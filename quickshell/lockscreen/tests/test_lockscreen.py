"""Static and mocked checks for the lockscreen designs and launcher."""
import configparser
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
THEMES = ROOT / 'themes'
MODULE = ROOT / 'imports/LockscreenComponents'
DESIGNS = sorted(path.parent for path in THEMES.rglob('Main.qml'))


def general(design):
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    parser.read(design / 'theme.conf')
    return dict(parser['General']) if parser.has_section('General') else {}


class DesignTests(unittest.TestCase):
    def qml_sources(self):
        return [*(design / 'Main.qml' for design in DESIGNS), *MODULE.glob('*.qml')]

    def test_password_submit_is_not_gated_on_quickshell(self):
        # The Quickshell bridge has no hostName, so gating login on the
        # "isQuickshell" check made some designs impossible to unlock.
        for path in self.qml_sources():
            lines = path.read_text().splitlines()
            for number, line in enumerate(lines):
                if re.search(r'\b(sddm|login)\.login\(', line):
                    context = '\n'.join(lines[max(0, number - 3):number + 1])
                    self.assertNotIn('isQuickshell', context, f'{path}:{number + 1}')

    def test_every_design_reaches_login(self):
        controller = (MODULE / 'LoginController.qml').read_text()
        self.assertIn('sddm.login(', controller)
        for design in DESIGNS:
            source = (design / 'Main.qml').read_text()
            for name in re.findall(r'^(\w+Design) \{', source, re.MULTILINE):
                source += (MODULE / f'{name}.qml').read_text()
            self.assertRegex(source, r'\b(sddm\.login|login\.login)\(', design.name)

    def test_bridge_identifies_itself_to_login_controller(self):
        self.assertIn('readonly property bool quickshellLock: true', (ROOT / 'AuthAdapter.qml').read_text())
        self.assertIn('sddm.quickshellLock === true', (MODULE / 'LoginController.qml').read_text())

    def test_backgrounds_come_from_theme_config(self):
        for design in DESIGNS:
            source = (design / 'Main.qml').read_text()
            self.assertFalse((design / 'BackgroundVideo.qml').exists(), design.name)
            self.assertNotIn('import QtMultimedia', source, design.name)
            if 'config.background' in source:
                background = general(design).get('background')
                self.assertTrue(background, f'{design.name} needs background= in theme.conf')
                self.assertTrue((design / background).is_file(), f'{design.name}: {background}')

    def test_shared_module_files_are_registered(self):
        registered = {line.split()[-1] for line in (MODULE / 'qmldir').read_text().splitlines()[1:] if line.strip()}
        internal = {'VideoPlayer.qml'}
        self.assertEqual(registered | internal, {path.name for path in MODULE.glob('*.qml')})
        self.assertIn('Qt.resolvedUrl("VideoPlayer.qml")', (MODULE / 'BackgroundVideo.qml').read_text())

    def test_material_variants_share_one_design(self):
        light, dark = THEMES / 'material-you', THEMES / 'material-you-dark'
        self.assertEqual((light / 'Main.qml').read_text(), (dark / 'Main.qml').read_text())
        self.assertEqual(general(light).get('themeMode'), 'light')
        self.assertEqual(general(dark).get('themeMode'), 'dark')


class SettingsTests(unittest.TestCase):
    def run_settings(self, *args):
        return subprocess.run(['python3', str(ROOT / 'scripts/settings.py'), *args],
                              capture_output=True, text=True)

    def test_missing_design_argument_is_a_usage_error(self):
        result = self.run_settings('select')
        self.assertEqual(result.returncode, 1)
        self.assertIn('Usage', result.stderr)
        self.assertNotIn('Traceback', result.stderr)

    def test_listed_designs_have_main_qml(self):
        listed = [line.split('\t')[0] for line in self.run_settings('list').stdout.splitlines()]
        self.assertEqual(sorted(listed), sorted(str(d.relative_to(THEMES)) for d in DESIGNS))


class LaunchTests(unittest.TestCase):
    def setUp(self):
        self.temp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.temp)
        home = self.temp / 'home'
        (home / '.config/quickshell').mkdir(parents=True)
        (home / '.config/quickshell/lockscreen').symlink_to(ROOT)
        (home / '.config/lockscreen').mkdir()
        (home / '.config/lockscreen/selected').write_text('material-you\n')
        runtime = self.temp / 'runtime'
        runtime.mkdir()
        bin_dir = self.temp / 'bin'
        bin_dir.mkdir()
        self.log = self.temp / 'calls.log'
        real_python = shutil.which('python3')
        fakes = {
            'flock': 'exit "${FAKE_FLOCK:-0}"',
            'pgrep': '[[ "$1" == -x ]] && exit "${FAKE_HYPRLOCK:-1}"; exit "${FAKE_OTHER_LOCK:-1}"',
            'quickshell': 'echo "quickshell $*" >> "$CALLS"; exit "${FAKE_QUICKSHELL:-0}"',
            'hyprlock': 'echo hyprlock >> "$CALLS"',
            'notify-send': 'exit 0',
            'python3': f'[[ -n "${{FAKE_PYTHON_FAIL:-}}" ]] && exit 1; exec "{real_python}" "$@"',
        }
        for name, body in fakes.items():
            path = bin_dir / name
            path.write_text('#!/usr/bin/env bash\n' + body + '\n')
            path.chmod(0o755)
        self.env = {'HOME': str(home), 'XDG_RUNTIME_DIR': str(runtime), 'CALLS': str(self.log),
                    'PATH': f'{bin_dir}:{os.environ["PATH"]}'}

    def launch(self, *args, **overrides):
        env = {**self.env, **overrides}
        result = subprocess.run(['bash', str(ROOT / 'scripts/launch.sh'), *args],
                                env=env, capture_output=True, text=True)
        calls = self.log.read_text().splitlines() if self.log.exists() else []
        return result, calls

    def test_normal_unlock_does_not_start_hyprlock(self):
        result, calls = self.launch('lock')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ['quickshell -n -c lockscreen'])

    def test_quickshell_failure_falls_back_to_hyprlock(self):
        _, calls = self.launch('lock', FAKE_QUICKSHELL='1')
        self.assertEqual(calls, ['quickshell -n -c lockscreen', 'hyprlock'])

    def test_failure_with_another_lock_instance_does_not_double_lock(self):
        _, calls = self.launch('lock', FAKE_QUICKSHELL='1', FAKE_OTHER_LOCK='0')
        self.assertEqual(calls, ['quickshell -n -c lockscreen'])

    def test_settings_failure_still_locks(self):
        _, calls = self.launch('lock', FAKE_PYTHON_FAIL='1')
        self.assertEqual(calls, ['hyprlock'])

    def test_existing_lock_is_left_alone(self):
        _, calls = self.launch('lock', FAKE_FLOCK='1')
        self.assertEqual(calls, [])
        _, calls = self.launch('lock', FAKE_HYPRLOCK='0')
        self.assertEqual(calls, [])

    def test_active_reports_held_lock(self):
        self.assertEqual(self.launch('active')[0].returncode, 1)
        (Path(self.env['XDG_RUNTIME_DIR']) / 'desktop-lockscreen.lock').touch()
        self.assertEqual(self.launch('active', FAKE_FLOCK='1')[0].returncode, 0)
        self.assertEqual(self.launch('active')[0].returncode, 1)
        self.assertEqual(self.launch('active', FAKE_HYPRLOCK='0')[0].returncode, 0)


if __name__ == '__main__':
    unittest.main()
