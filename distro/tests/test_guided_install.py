import ast
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import tempfile
import unittest

DISTRO = Path(__file__).resolve().parents[1]
GUIDED = DISTRO / "archinstall"
loader = importlib.machinery.SourceFileLoader("eitr_guided_install", str(GUIDED / "eitr-guided-install"))
spec = importlib.util.spec_from_loader("eitr_guided_install", loader)
guided = importlib.util.module_from_spec(spec)
loader.exec_module(guided)

TEMPLATE = json.loads((GUIDED / "user_configuration.json").read_text())
DISK = {"path": "/dev/test-disk", "size": 500 * 1024 ** 3, "sector_size": 4096,
        "model": "Test", "transport": "nvme"}


def root_snapshot_paths():
    """The paths eitr-system's snapshots-check requires inside the root snapshot."""
    tree = ast.parse((DISTRO / "system/eitr-system.py").read_text())
    for node in ast.walk(tree):
        if isinstance(node, ast.Tuple) and all(isinstance(item, ast.Constant) for item in node.elts):
            values = [item.value for item in node.elts]
            if "/var/lib/pacman" in values:
                return values
    raise AssertionError("snapshot_supported() paths not found in eitr-system.py")


def root_partition(config):
    (device,) = config["disk_config"]["device_modifications"]
    return next(part for part in device["partitions"] if part["btrfs"])


class ConfigurationTests(unittest.TestCase):
    def test_subvolumes_keep_snapshot_paths_inside_root(self):
        subvolumes = {item["mountpoint"]: item["name"] for item in root_partition(TEMPLATE)["btrfs"]}
        self.assertEqual(subvolumes["/"], "@")
        required = [PurePosixPath(path) for path in root_snapshot_paths()]
        self.assertTrue(required)
        for mountpoint in subvolumes:
            if mountpoint == "/":
                continue
            for path in required:
                self.assertFalse(path == PurePosixPath(mountpoint) or PurePosixPath(mountpoint) in path.parents,
                                 f"{mountpoint} would split {path} out of the root snapshot")
        # Snapper's `create-config /` must create /.snapshots itself.
        self.assertIn('"create-config", "/"', (DISTRO / "system/eitr-system.py").read_text())
        self.assertNotIn("/.snapshots", subvolumes)
        self.assertEqual(set(subvolumes), {"/", "/home", "/var/log", "/var/cache/pacman/pkg"})

    def test_encrypted_btrfs_root_with_limine_on_a_fat_boot_partition(self):
        disk = TEMPLATE["disk_config"]
        (device,) = disk["device_modifications"]
        esp = next(part for part in device["partitions"] if part["mountpoint"] == "/boot")
        root = root_partition(TEMPLATE)
        self.assertEqual((esp["fs_type"], set(esp["flags"])), ("fat32", {"boot", "esp"}))
        self.assertEqual(root["fs_type"], "btrfs")
        self.assertEqual(disk["disk_encryption"]["encryption_type"], "luks")
        self.assertEqual(disk["disk_encryption"]["partitions"], [root["obj_id"]])
        self.assertEqual(TEMPLATE["bootloader_config"]["bootloader"], "Limine")
        self.assertFalse(TEMPLATE["bootloader_config"]["uki"])
        self.assertNotIn("btrfs_options", disk)  # Eitr's snapshots-setup owns Snapper.

    def test_networking_audio_and_profile(self):
        services = set(TEMPLATE["services"])
        self.assertEqual(services, {"iwd", "systemd-networkd", "systemd-resolved"})
        self.assertNotIn("network_config", TEMPLATE)  # archinstall's iwd mode would also run DHCP in iwd.
        text = json.dumps(TEMPLATE).lower()
        self.assertNotIn("networkmanager", text)
        self.assertEqual(TEMPLATE["app_config"]["audio_config"]["audio"], "pipewire")
        self.assertEqual(TEMPLATE["profile_config"]["profile"]["main"], "Minimal")
        self.assertIn("multilib", TEMPLATE["mirror_config"]["optional_repositories"])
        self.assertLessEqual({"git", "python", "sudo", "iwd"}, set(TEMPLATE["packages"]))

    def test_nothing_personal_or_machine_specific_is_hardcoded(self):
        for key in ("users", "!users", "auth_config", "root_enc_password", "!root-password",
                    "encryption_password", "hostname", "locale_config", "timezone",
                    "archinstall-language", "network_config"):
            self.assertNotIn(key, TEMPLATE)
        (device,) = TEMPLATE["disk_config"]["device_modifications"]
        self.assertIsNone(device["device"])
        self.assertTrue(all(part["dev_path"] is None for part in device["partitions"]))
        disk_names = re.compile(r"/dev/(sd|hd|vd|xvd|nvme|mmcblk|disk/by-)")
        for path in (GUIDED / "user_configuration.json", GUIDED / "eitr-guided-install",
                     GUIDED / "first-login.sh"):
            self.assertIsNone(disk_names.search(path.read_text()), path)


class GuidedInstallTests(unittest.TestCase):
    def test_build_config_fills_only_the_selected_disk(self):
        config = guided.build_config(TEMPLATE, DISK)
        (device,) = config["disk_config"]["device_modifications"]
        self.assertEqual(device["device"], DISK["path"])
        esp, root = device["partitions"]
        self.assertEqual(root["start"]["value"], esp["start"]["value"] + esp["size"]["value"])
        end = root["start"]["value"] + root["size"]["value"]
        self.assertEqual(end, DISK["size"] // 1024 ** 2 - 1)
        self.assertEqual({part["start"]["sector_size"]["value"] for part in (esp, root)}, {4096})
        self.assertNotIn("eitr_comment", config)
        self.assertIsNone(TEMPLATE["disk_config"]["device_modifications"][0]["device"])

    def test_small_disks_are_rejected(self):
        with self.assertRaises(guided.GuidedInstallError):
            guided.build_config(TEMPLATE, dict(DISK, size=20 * 1024 ** 3))

    def test_candidate_disks_skip_media_read_only_and_small_devices(self):
        big = str(200 * 1024 ** 3)
        lsblk = {"blockdevices": [
            {"path": "/dev/a", "size": big, "type": "disk", "ro": False, "model": "Disk A ", "tran": "sata", "log-sec": 512},
            {"path": "/dev/live", "size": big, "type": "disk", "ro": False, "model": None, "tran": "usb", "log-sec": 512},
            {"path": "/dev/rom", "size": big, "type": "rom", "ro": False},
            {"path": "/dev/loop0", "size": big, "type": "loop", "ro": False},
            {"path": "/dev/locked", "size": big, "type": "disk", "ro": True},
            {"path": "/dev/tiny", "size": str(8 * 1024 ** 3), "type": "disk", "ro": False},
        ]}
        disks = guided.candidate_disks(lsblk, {"/dev/live"})
        self.assertEqual([disk["path"] for disk in disks], ["/dev/a"])
        self.assertEqual(disks[0]["model"], "Disk A")

    def test_desktop_users_are_regular_login_accounts(self):
        passwd = ("root:x:0:0::/root:/bin/bash\n"
                  "nobody:x:65534:65534:Kernel Overflow User:/:/usr/bin/nologin\n"
                  "alex:x:1000:1000::/home/alex:/bin/bash\n"
                  "svc:x:1001:1001::/home/svc:/usr/bin/nologin\n")
        self.assertEqual(guided.desktop_users(passwd),
                         [{"name": "alex", "uid": 1000, "gid": 1000, "home": "/home/alex"}])

    def test_login_hook_is_added_once(self):
        profile = guided.with_login_hook("[[ -f ~/.bashrc ]] && . ~/.bashrc", "eitr")
        self.assertEqual(guided.with_login_hook(profile, "eitr"), profile)
        self.assertTrue(profile.startswith("[[ -f ~/.bashrc ]] && . ~/.bashrc\n"))
        self.assertIn("$HOME/eitr/distro/archinstall/first-login.sh", profile)
        self.assertIn("/dev/tty1", profile)
        result = subprocess.run(["bash", "-n"], input=profile, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_build_iso_ships_the_guided_installer(self):
        script = (DISTRO / "build-iso.sh").read_text()
        self.assertIn("/usr/local/bin/eitr-guided-install", script)
        self.assertIn("source-version.sh", script)
        self.assertIn("file_permissions[%q]", script)


@unittest.skipUnless(importlib.util.find_spec("archinstall"), "archinstall is not installed")
class ArchinstallParserTests(unittest.TestCase):
    """Parse the generated config with archinstall's own models (runs where archinstall exists)."""

    def setUp(self):
        # Unprivileged archinstall writes install.log into the working directory.
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.addCleanup(os.chdir, os.getcwd())
        os.chdir(directory.name)

    def test_archinstall_accepts_the_generated_layout(self):
        from types import SimpleNamespace
        from unittest.mock import patch
        from archinstall.lib.args import ArchConfig, Arguments
        from archinstall.lib.disk.device_handler import device_handler
        from archinstall.lib.models.device import SectorSize, Size, Unit

        for sector in (512, 4096):
            disk = dict(DISK, size=DISK["size"] + 12345, sector_size=sector)
            config = guided.build_config(TEMPLATE, disk)
            config["encryption_password"] = "test passphrase"
            size = SectorSize(sector, Unit.B)
            device = SimpleNamespace(device_info=SimpleNamespace(
                path=Path(disk["path"]), total_size=Size(disk["size"], Unit.B, size), sector_size=size))
            with self.subTest(sector=sector), \
                    patch.object(type(device_handler), "get_device",
                                 lambda _self, path: device if str(path) == disk["path"] else None):
                arch = ArchConfig.from_config(config, Arguments())
                (modification,) = arch.disk_config.device_modifications
                esp, root = modification.partitions
                self.assertEqual(str(esp.mountpoint), "/boot")
                self.assertEqual([str(item.mountpoint) for item in root.btrfs_subvols],
                                 ["/", "/home", "/var/log", "/var/cache/pacman/pkg"])
                self.assertEqual(arch.disk_config.disk_encryption.partitions, [root])
                self.assertNotIn("test passphrase", arch.user_config_to_json())


class FirstLoginTests(unittest.TestCase):
    def run_first_login(self, home, answer="", online=True):
        binaries = home / "bin"
        binaries.mkdir(exist_ok=True)
        (binaries / "getent").write_text(f"#!/bin/sh\nexit {0 if online else 2}\n")
        (binaries / "getent").chmod(0o755)
        environment = {key: value for key, value in os.environ.items() if not key.startswith("XDG_")}
        environment.update(HOME=str(home), PATH=f"{binaries}{os.pathsep}{os.environ['PATH']}")
        return subprocess.run(["bash", str(GUIDED / "first-login.sh")], input=answer + "\n",
                              capture_output=True, text=True, env=environment)

    def test_offline_login_explains_wifi_and_exits_cleanly(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_first_login(Path(directory), online=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("iwctl station", result.stdout)

    def test_declining_leaves_the_offer_for_next_login(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_first_login(Path(directory), answer="n")
            self.assertFalse((Path(directory) / ".local/state/eitr/guided-install-complete").exists())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Skipped", result.stdout)

    def test_completed_install_is_not_offered_again(self):
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / ".local/state/eitr/guided-install-complete"
            marker.parent.mkdir(parents=True)
            marker.touch()
            result = self.run_first_login(Path(directory))
        self.assertEqual((result.returncode, result.stdout), (0, ""))


if __name__ == "__main__":
    unittest.main()
