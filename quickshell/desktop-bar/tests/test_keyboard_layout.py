import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('keyboard_layout',
    Path(__file__).parents[1] / 'scripts/keyboard-layout.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class KeyboardLayoutTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.state = Path(self.directory.name) / 'keyboard-layouts.lua'
        self.keyboard = {'layout': 'us,us', 'variant': ',intl'}
        self.catalog = [{'layout': 'br', 'variant': '', 'label': 'Portuguese (Brazil)'}]

    def test_catalog_contains_base_and_variants(self):
        pairs = {(entry['layout'], entry['variant']) for entry in module.catalog()}
        self.assertIn(('us', 'intl'), pairs)
        self.assertIn(('br', ''), pairs)

    def test_add_preserves_existing_variants_and_saves(self):
        with patch.object(module, 'STATE', self.state), patch.object(module.shutil, 'which', return_value=None), \
                patch.object(module.subprocess, 'run') as run:
            module.append_layout(self.keyboard, 'br', '', self.catalog)
            self.assertEqual(self.state.read_text(), 'return { layout = "us,us,br", variant = ",intl," }\n')
            run.assert_called_once_with(['hyprctl', 'reload'], check=True, capture_output=True, timeout=10)

    def test_duplicate_unknown_and_group_limit_do_not_write(self):
        with patch.object(module, 'STATE', self.state), patch.object(module.subprocess, 'run') as run:
            with self.assertRaises(ValueError):
                module.append_layout(self.keyboard, 'invalid', '', self.catalog)
            with self.assertRaises(ValueError):
                module.append_layout({'layout': 'br'}, 'br', '', self.catalog)
            with self.assertRaises(ValueError):
                module.append_layout({'layout': 'us,us,de,fr', 'variant': ',intl,,'}, 'br', '', self.catalog)
            self.assertFalse(self.state.exists())
            run.assert_not_called()

    def test_reload_failure_restores_previous_file(self):
        original = 'return { layout = "us,us", variant = ",intl" }\n'
        self.state.write_text(original)
        with patch.object(module, 'STATE', self.state), patch.object(module.shutil, 'which', return_value=None), \
                patch.object(module.subprocess, 'run', side_effect=[subprocess.CalledProcessError(1, 'hyprctl'), None]):
            with self.assertRaises(subprocess.CalledProcessError):
                module.append_layout(self.keyboard, 'br', '', self.catalog)
        self.assertEqual(self.state.read_text(), original)


if __name__ == '__main__':
    unittest.main()
