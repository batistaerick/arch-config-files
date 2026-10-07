import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("obs_control", Path(__file__).parents[1] / "scripts/obs-control.py")
obs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(obs)


class ObsControlTests(unittest.TestCase):
    def test_start_launches_minimized_and_waits_before_recording(self):
        with patch.object(obs.subprocess, "run", side_effect=[SimpleNamespace(returncode=1), SimpleNamespace(returncode=0), SimpleNamespace(returncode=0)]) as run, \
                patch.object(obs.subprocess, "Popen") as launch, \
                patch.object(Path, "read_text", return_value='{"server_enabled":true,"auth_required":false}'):
            self.assertEqual(obs.control("record"), "Command applied")
            self.assertEqual(launch.call_args.args[0], ["obs", "--minimize-to-tray"])
            self.assertEqual(run.call_args_list[-1].args[0][-2:], ["recording", "start"])

    def test_stop_does_not_launch_obs(self):
        with patch.object(obs.subprocess, "run", return_value=SimpleNamespace(returncode=1)), \
                patch.object(obs.subprocess, "Popen") as launch:
            with self.assertRaisesRegex(RuntimeError, "not running"):
                obs.control("stop")
            launch.assert_not_called()

    def test_invalid_action_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, "Unknown"):
            obs.control("quit")
