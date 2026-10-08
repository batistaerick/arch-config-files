import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("obs_control", Path(__file__).parents[1] / "scripts/obs-control.py")
obs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(obs)


class ObsControlTests(unittest.TestCase):
    def test_recording_states(self):
        self.assertEqual(obs.parse_status("Recording Status:\n Active: false"), {"active": False, "paused": False})
        self.assertEqual(obs.parse_status("Recording Status:\n Active: true\n Paused: true"), {"active": True, "paused": True})
        self.assertEqual(obs.parse_status("Recording Status:\n Active: true\n Paused: false"), {"active": True, "paused": False})
        with self.assertRaises(RuntimeError):
            obs.parse_status("Connection failed")

    def test_status_without_obs_does_not_launch_it(self):
        with patch.object(obs.subprocess, "run", return_value=SimpleNamespace(returncode=1)), \
                patch.object(obs.subprocess, "Popen") as launch:
            state = obs.status()
            self.assertTrue(state["ready"])
            self.assertFalse(state["recording"])
            self.assertFalse(state["streaming"])
            launch.assert_not_called()

    def test_status_reads_recording_pause_and_streaming(self):
        with patch.object(obs.subprocess, "run", side_effect=[
                SimpleNamespace(returncode=0),
                SimpleNamespace(returncode=0, stdout="Active: true\nPaused: true"),
                SimpleNamespace(returncode=0, stdout="Active: true")]), \
                patch.object(obs, "websocket_command", return_value=["obs-cmd"]):
            state = obs.status()
            self.assertTrue(state["ready"])
            self.assertTrue(state["recording"])
            self.assertTrue(state["paused"])
            self.assertTrue(state["streaming"])

    def test_failed_status_disables_controls(self):
        with patch.object(obs.subprocess, "run", return_value=SimpleNamespace(returncode=0)), \
                patch.object(obs, "websocket_command", side_effect=RuntimeError("Enable OBS WebSocket in Tools first")):
            state = obs.status()
            self.assertFalse(state["ready"])
            self.assertIn("WebSocket", state["error"])

    def test_folder_opens_records_without_launching_obs(self):
        with patch.object(Path, "mkdir") as mkdir, patch.object(obs.subprocess, "Popen") as launch:
            obs.control("folder")
            mkdir.assert_called_once_with(parents=True, exist_ok=True)
            self.assertEqual(launch.call_args.args[0], ["xdg-open", str(Path.home() / "Videos/Records")])

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
