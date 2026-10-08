import importlib.util
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("obs_control", Path(__file__).parents[1] / "scripts/obs-control.py")
obs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(obs)


class ObsControlTests(unittest.TestCase):
    def test_prepare_does_not_start_capture(self):
        with patch.object(obs.subprocess, "run", side_effect=[SimpleNamespace(returncode=1), SimpleNamespace(returncode=0)]) as run, \
                patch.object(obs, "websocket_command", return_value=["obs-cmd"]), \
                patch.object(obs, "launch_background"), patch.object(obs, "apply_capture_options") as apply:
            self.assertEqual(obs.control("prepare"), "OBS ready")
            apply.assert_called_once_with(["obs-cmd"])
            self.assertEqual(run.call_args.args[0], ["obs-cmd", "info"])

    def test_capture_options_persist_without_launching_obs(self):
        options = {key: {"enabled": False, "available": True, "sources": []} for key in ("audio", "mic", "webcam")}
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(obs, "OPTIONS_FILE", Path(directory) / "options.json"), \
                patch.object(obs, "capture_options", return_value=options), patch.object(obs.subprocess, "Popen") as launch:
            obs.save_capture_option("mic", "true")
            self.assertIn('"mic": true', obs.OPTIONS_FILE.read_text())
            launch.assert_not_called()

    def test_missing_camera_cannot_be_enabled(self):
        with patch.object(obs, "capture_options", return_value={"webcam": {"available": False}}):
            with self.assertRaisesRegex(RuntimeError, "Configure"):
                obs.save_capture_option("webcam", "true")

    def test_audio_choices_apply_to_obs_not_system_volume(self):
        options = {"audio": {"enabled": False, "sources": ["Desktop Audio"]},
                   "mic": {"enabled": True, "sources": ["Mic/Aux"]}, "webcam": {"sources": []}}
        scene = {"current_scene": "Scene", "sources": [
            {"name": "Screen", "id": "pipewire-screen-capture-source"},
            {"name": "Scene", "settings": {"items": [{"name": "Screen", "visible": True}]}}]}
        with patch.object(obs, "capture_options", return_value=options), patch.object(obs, "scene_collection", return_value=scene), \
                patch.object(obs.subprocess, "run", return_value=SimpleNamespace(returncode=0)) as run:
            obs.apply_capture_options(["obs-cmd"])
            self.assertEqual(run.call_args_list[0].args[0], ["obs-cmd", "audio", "mute", "Desktop Audio"])
            self.assertEqual(run.call_args_list[1].args[0], ["obs-cmd", "audio", "unmute", "Mic/Aux"])

    def test_audio_and_mic_choices_are_independent(self):
        scene = {"current_scene": "Scene", "sources": [
            {"name": "Screen", "id": "pipewire-screen-capture-source"},
            {"name": "Scene", "settings": {"items": [{"name": "Screen"}]}}]}
        for audio in (False, True):
            for mic in (False, True):
                with self.subTest(audio=audio, mic=mic):
                    options = {"audio": {"enabled": audio, "sources": ["Desktop Audio"]},
                               "mic": {"enabled": mic, "sources": ["Mic/Aux"]},
                               "webcam": {"sources": []}}
                    with patch.object(obs, "capture_options", return_value=options), \
                            patch.object(obs, "scene_collection", return_value=scene), \
                            patch.object(obs.subprocess, "run", return_value=SimpleNamespace(returncode=0)) as run:
                        obs.apply_capture_options(["obs-cmd"])
                        self.assertEqual([call.args[0] for call in run.call_args_list], [
                            ["obs-cmd", "audio", "unmute" if audio else "mute", "Desktop Audio"],
                            ["obs-cmd", "audio", "unmute" if mic else "mute", "Mic/Aux"]])

    def test_window_only_scene_is_not_recorded(self):
        scene = {"current_scene": "Scene", "sources": [
            {"name": "Window", "id": "pipewire-window-capture-source"},
            {"name": "Scene", "settings": {"items": [{"name": "Window", "visible": True}]}}]}
        with patch.object(obs, "scene_collection", return_value=scene), patch.object(obs.subprocess, "run") as run:
            with self.assertRaisesRegex(RuntimeError, "full-screen"):
                obs.apply_capture_options(["obs-cmd"])
            run.assert_not_called()

    def test_camera_uses_scene_name_without_cli_preamble(self):
        options = {"audio": {"sources": []}, "mic": {"sources": []},
                   "webcam": {"enabled": True, "sources": ["Camera"]}}
        scene = {"current_scene": "Scene", "sources": [
            {"name": "Screen", "id": "pipewire-screen-capture-source"},
            {"name": "Scene", "settings": {"items": [{"name": "Screen"}]}}]}
        with patch.object(obs, "capture_options", return_value=options), \
                patch.object(obs, "scene_collection", return_value=scene), \
                patch.object(obs.subprocess, "run", side_effect=[
                    SimpleNamespace(returncode=0, stdout="Executing: Get current scene\nCurrent scene: Scene\n"),
                    SimpleNamespace(returncode=0)]) as run:
            obs.apply_capture_options(["obs-cmd"])
            self.assertEqual(run.call_args.args[0], ["obs-cmd", "scene-item", "enable", "Scene", "Camera"])

    def test_idle_obs_exits_after_successful_stop(self):
        with patch.object(obs, "status", return_value={"ready": True, "running": True, "recording": False, "streaming": False}), \
                patch.object(obs.subprocess, "run", side_effect=[SimpleNamespace(returncode=0, stdout="42\n"), SimpleNamespace(returncode=0, stdout="[]")]), \
                patch.object(obs.os, "kill") as stop:
            self.assertTrue(obs.close_if_idle())
            stop.assert_called_once_with(42, obs.signal.SIGTERM)

    def test_active_or_unknown_obs_is_not_closed(self):
        for changes in ({"streaming": True}, {"recording": True}, {"ready": False}):
            state = {"ready": True, "running": True, "recording": False, "streaming": False, **changes}
            with patch.object(obs, "status", return_value=state), patch.object(obs.os, "kill") as stop, patch.object(obs.time, "sleep"):
                self.assertFalse(obs.close_if_idle())
                stop.assert_not_called()

    def test_idle_window_closes_through_hyprland(self):
        state = {"ready": True, "running": True, "recording": False, "streaming": False}
        with patch.object(obs, "status", return_value=state), \
                patch.object(obs.subprocess, "run", side_effect=[
                    SimpleNamespace(returncode=0, stdout="42\n"),
                    SimpleNamespace(returncode=0, stdout='[{"pid":42,"class":"com.obsproject.Studio","address":"0x123"}]'),
                    SimpleNamespace(returncode=0)]) as run, patch.object(obs.os, "kill") as stop:
            self.assertTrue(obs.close_if_idle())
            self.assertIn("hl.dsp.window.close", run.call_args.args[0][-1])
            self.assertIn("address:0x123", run.call_args.args[0][-1])
            stop.assert_not_called()

    def test_multiple_obs_instances_are_not_closed(self):
        with patch.object(obs, "status", return_value={"ready": True, "running": True, "recording": False, "streaming": False}), \
                patch.object(obs.subprocess, "run", return_value=SimpleNamespace(returncode=0, stdout="42\n43\n")), \
                patch.object(obs.os, "kill") as stop:
            self.assertFalse(obs.close_if_idle())
            stop.assert_not_called()

    def test_stop_waits_for_success_before_exiting(self):
        with patch.object(obs.subprocess, "run", return_value=SimpleNamespace(returncode=0)), \
                patch.object(obs, "websocket_command", return_value=["obs-cmd"]), \
                patch.object(obs, "close_if_idle") as close:
            obs.control("stop")
            close.assert_called_once()

    def test_failed_stop_does_not_exit(self):
        with patch.object(obs.subprocess, "run", side_effect=[SimpleNamespace(returncode=0), SimpleNamespace(returncode=1)]), \
                patch.object(obs, "websocket_command", return_value=["obs-cmd"]), \
                patch.object(obs, "close_if_idle") as close:
            with self.assertRaises(RuntimeError):
                obs.control("stop")
            close.assert_not_called()

    def test_background_launch_uses_lua_workspace_rule(self):
        with patch.object(obs.subprocess, "run", return_value=SimpleNamespace(returncode=0)) as run:
            obs.launch_background()
            self.assertEqual(run.call_args.args[0][:2], ["hyprctl", "eval"])
            self.assertIn("special:obs-background silent", run.call_args.args[0][2])
            self.assertIn("obs --minimize-to-tray", run.call_args.args[0][2])

    def test_open_restores_background_obs_to_current_workspace(self):
        clients = '[{"class":"com.obsproject.Studio","address":"0x123","workspace":{"name":"special:obs-background"}}]'
        with patch.object(obs.subprocess, "run", side_effect=[
                SimpleNamespace(returncode=0, stdout=clients),
                SimpleNamespace(returncode=0, stdout='{"id":3}'),
                SimpleNamespace(returncode=0), SimpleNamespace(returncode=0)]) as run:
            obs.reveal_window()
            self.assertIn("workspace = 3", run.call_args_list[2].args[0][-1])
            self.assertIn("address:0x123", run.call_args_list[2].args[0][-1])
            self.assertIn("hl.dsp.focus", run.call_args.args[0][-1])

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
                patch.object(obs, "launch_background") as launch, \
                patch.object(Path, "read_text", return_value='{"server_enabled":true,"auth_required":false}'):
            self.assertEqual(obs.control("record"), "Command applied")
            launch.assert_called_once_with()
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
