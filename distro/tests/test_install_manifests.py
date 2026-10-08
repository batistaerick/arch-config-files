from pathlib import Path
import configparser
import unittest


DISTRO = Path(__file__).resolve().parents[1]


class InstallManifestTests(unittest.TestCase):
    def test_netflix_graphics_are_isolated_from_normal_chrome(self):
        root = DISTRO.parent
        script = (root / "HOME_FILES/.local/bin/netflix").read_text()
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
