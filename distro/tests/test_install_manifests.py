from pathlib import Path
import configparser
import json
import os
import subprocess
import tempfile
import unittest


DISTRO = Path(__file__).resolve().parents[1]


class InstallManifestTests(unittest.TestCase):
    @unittest.skipIf(os.geteuid() == 0, "Installer intentionally rejects root")
    def test_non_executable_installer_runs_preflight_before_installing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            installer = root / "install.sh"
            installer.write_text((DISTRO / "install.sh").read_text())
            installer.chmod(0o644)
            binaries = root / "bin"
            binaries.mkdir()
            for name in ("pacman", "sudo", "systemctl"):
                mock = binaries / name
                mock.write_text("#!/bin/sh\nexit 0\n")
                mock.chmod(0o755)
            env = dict(os.environ, HOME=directory,
                       PATH=str(binaries) + os.pathsep + os.environ["PATH"])
            result = subprocess.run(["bash", str(installer)], env=env,
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn("NetworkManager is enabled", result.stderr)
            self.assertNotIn("Permission denied", result.stderr)

    def test_removed_packages_stay_out_of_install_manifests(self):
        packages = set()
        for filename in ("packages.txt", "apps.txt", "aur-packages.txt", "aur-apps.txt"):
            packages.update(line.strip() for line in (DISTRO / filename).read_text().splitlines()
                            if line.strip() and not line.startswith("#"))
        self.assertFalse({"swaync", "walker-debug", "mongosh-bin-debug", "cef",
                          "bruno-bin", "ngrok", "kubectl", "helm", "minikube",
                          "cups", "hplip", "system-config-printer", "xf86-input-wacom"} & packages)
        installer = (DISTRO / "install.sh").read_text()
        self.assertIn("https://aur.archlinux.org/yay.git", installer)
        self.assertIn('--mflags "--options !debug"', installer)
        self.assertNotIn('bash "$repo_root/distro/install-development.sh"', installer)
        self.assertNotIn('npm install --global', installer)
        self.assertNotIn('https://claude.ai/install.sh', installer)

    def test_direct_desktop_helper_dependencies_are_explicit(self):
        packages = set((DISTRO / "packages.txt").read_text().splitlines())
        self.assertFalse({"desktop-file-utils", "lm_sensors", "qrencode", "iproute2",
                          "iputils", "procps-ng", "util-linux"} - packages)

    def test_development_runtimes_are_managed_not_explicit_system_packages(self):
        packages = set()
        for filename in ("packages.txt", "apps.txt", "aur-packages.txt", "aur-apps.txt"):
            packages.update(line.strip() for line in (DISTRO / filename).read_text().splitlines()
                            if line.strip() and not line.startswith("#"))
        self.assertFalse({"nodejs", "npm"} & packages)
        self.assertFalse({package for package in packages if package.startswith(("jdk", "jre"))})
        self.assertFalse({"go", "rustup", "fvm", "python-pip"} & packages)
        self.assertIn("python", packages)  # Required by desktop helpers.

    def test_snapshot_and_gaming_dependencies_are_explicit(self):
        packages = set((DISTRO / "packages.txt").read_text().splitlines())
        self.assertFalse({"snapper", "flatpak", "fprintd", "pam-u2f", "lazygit", "lazydocker"} - packages)
        installer = (DISTRO / "install.sh").read_text()
        self.assertIn("com.nvidia.geforcenow", installer)
        self.assertIn("snapshots-setup", installer)
        self.assertIn("/usr/local/lib/eitr/eitr-system", installer)

    @unittest.skipIf(os.geteuid() == 0, "Development installer intentionally rejects root")
    def test_optional_node_setup_uses_lts_with_mocked_manager(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            log = home / "calls"
            nvm = home / ".nvm/nvm.sh"
            sdk = home / ".sdkman/bin/sdkman-init.sh"
            binaries = home / "bin"
            nvm.parent.mkdir(parents=True)
            sdk.parent.mkdir(parents=True)
            binaries.mkdir()
            nvm.write_text('nvm() { printf "nvm %s\\n" "$*" >> "$TEST_LOG"; }\n')
            sdk.write_text('sdk() { printf "sdk %s\\n" "$*" >> "$TEST_LOG"; }\n')
            npm = binaries / "npm"
            npm.write_text('#!/bin/bash\nprintf "npm %s\\n" "$*" >> "$TEST_LOG"\n')
            npm.chmod(0o755)
            curl = binaries / "curl"
            curl.write_text('#!/bin/bash\necho "Unexpected network access" >&2\nexit 99\n')
            curl.chmod(0o755)
            env = dict(os.environ, HOME=directory, TEST_LOG=str(log),
                       PATH=str(binaries) + os.pathsep + os.environ["PATH"])
            script = DISTRO.parent / "walker/scripts/actions/install/development.sh"
            subprocess.run(["bash", str(script), "node"],
                           env=env, capture_output=True, text=True, check=True)
            calls = log.read_text()
            self.assertIn("nvm install --lts", calls)
            self.assertIn("nvm alias default lts/*", calls)
            self.assertIn("nvm use default", calls)
            self.assertNotIn("npm install", calls)
            self.assertNotIn("sdk install", calls)
            self.assertFalse((home / ".zshrc").exists())

    def test_streaming_launchers_build_isolated_commands(self):
        scripts = DISTRO.parent / "HOME_FILES/.local/bin"
        with tempfile.TemporaryDirectory() as directory:
            mock = Path(directory) / "google-chrome-stable"
            mock.write_text('#!/usr/bin/env python3\nimport json,sys\nprint(json.dumps(sys.argv[1:]))\n')
            mock.chmod(0o755)
            env = dict(os.environ, PATH=directory + os.pathsep + os.environ["PATH"], XDG_CONFIG_HOME=directory)
            for provider in ("netflix", "crunchyroll"):
                for mode in ("accelerated", "software"):
                    with self.subTest(provider=provider, mode=mode):
                        result = subprocess.run([str(scripts / provider), mode], env=env,
                                                capture_output=True, text=True, check=True)
                        args = json.loads(result.stdout)
                        suffix = "-software" if mode == "software" else ""
                        self.assertIn(f"--user-data-dir={directory}/{provider}-chrome{suffix}", args)
                        self.assertIn(f"--app=https://www.{provider}.com/", args)
                        self.assertEqual("--disable-gpu" in args, mode == "software")
                        self.assertIn("--ozone-platform=x11", args)

    def test_netflix_graphics_are_isolated_from_normal_chrome(self):
        root = DISTRO.parent
        script = (root / "HOME_FILES/.local/bin/streaming-app").read_text()
        self.assertIn('--user-data-dir="$profile"', script)
        self.assertIn('--ozone-platform=x11', script)
        self.assertIn('flags+=(--disable-gpu)', script)
        launcher = configparser.ConfigParser(interpolation=None)
        launcher.read(root / "HOME_FILES/.local/share/applications/netflix.desktop")
        self.assertIn('$HOME/.local/bin/netflix', launcher["Desktop Entry"]["Exec"])
        self.assertIn('$HOME/.local/bin/netflix', launcher["Desktop Action Software"]["Exec"])
        self.assertTrue(launcher["Desktop Action Software"]["Exec"].endswith(' software"'))

    def test_gnome_videos_launcher_uses_scoped_graphics_fix(self):
        root = DISTRO.parent
        launcher = configparser.ConfigParser(interpolation=None)
        launcher.read(root / "HOME_FILES/.local/share/applications/org.gnome.Totem.desktop")
        self.assertEqual(launcher["Desktop Entry"]["Exec"], "env GDK_GL=gles totem %U")
        self.assertFalse(launcher["Desktop Entry"].getboolean("DBusActivatable"))
        associations = configparser.ConfigParser(interpolation=None)
        associations.read(root / "mimeapps.list")
        self.assertEqual(associations["Default Applications"]["video/mp4"], "org.gnome.Totem.desktop")

    def test_mpv_is_not_installed(self):
        packages = (DISTRO / "packages.txt").read_text().splitlines()
        self.assertNotIn("mpv", packages)

    def test_common_media_backends_and_steam_are_explicit(self):
        packages = set()
        for filename in ("packages.txt", "apps.txt"):
            packages.update(line.strip() for line in (DISTRO / filename).read_text().splitlines()
                            if line.strip() and not line.startswith("#"))
        required = {"ffmpeg", "qt6-multimedia-ffmpeg", "gstreamer", "gst-libav",
                    "gst-plugins-base", "gst-plugins-good", "gst-plugins-bad",
                    "gst-plugins-ugly", "gst-plugin-pipewire", "steam"}
        self.assertFalse(required - packages, f"Missing packages: {required - packages}")


if __name__ == "__main__":
    unittest.main()
