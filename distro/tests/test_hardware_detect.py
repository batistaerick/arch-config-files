import os
from pathlib import Path
import subprocess
import tempfile
import unittest


DETECTOR = Path(__file__).resolve().parents[1] / "hardware/detect.sh"


class HardwareDetectionTests(unittest.TestCase):
    def run_detector(self, cpu, vendors, nvidia_driver=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cpuinfo = root / "cpuinfo"
            cpuinfo.write_text(f"vendor_id\t: {cpu}\n")
            pci = root / "pci"
            pci.mkdir()
            for index, vendor in enumerate(vendors):
                device = pci / str(index)
                device.mkdir()
                (device / "class").write_text("0x030000\n")
                (device / "vendor").write_text(vendor + "\n")
            env = os.environ.copy()
            env.update(HARDWARE_SYSFS_ROOT=str(pci), HARDWARE_CPUINFO=str(cpuinfo))
            env.pop("DISTRO_NVIDIA_DRIVER", None)
            if nvidia_driver:
                env["DISTRO_NVIDIA_DRIVER"] = nvidia_driver
            return subprocess.run(["bash", str(DETECTOR)], env=env,
                                  capture_output=True, text=True, check=False)

    def test_amd_cpu_and_gpu(self):
        result = self.run_detector("AuthenticAMD", ["0x1002"])
        self.assertEqual(result.returncode, 0, result.stderr)
        packages = set(result.stdout.splitlines())
        self.assertTrue({"amd-ucode", "mesa", "lib32-mesa", "vulkan-radeon",
                         "lib32-vulkan-radeon", "lib32-vulkan-icd-loader"} <= packages)
        self.assertNotIn("intel-ucode", packages)

    def test_intel_cpu_and_gpu(self):
        result = self.run_detector("GenuineIntel", ["0x8086"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue({"intel-ucode", "vulkan-intel", "lib32-vulkan-intel"} <=
                        set(result.stdout.splitlines()))

    def test_nvidia_requires_explicit_generation_choice(self):
        result = self.run_detector("GenuineIntel", ["0x8086", "0x10de"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("DISTRO_NVIDIA_DRIVER=open", result.stderr)
        selected = self.run_detector("GenuineIntel", ["0x8086", "0x10de"], "open")
        self.assertEqual(selected.returncode, 0, selected.stderr)
        self.assertTrue({"nvidia-open", "lib32-nvidia-utils", "nvidia-settings",
                         "nvidia-prime", "vulkan-intel"} <= set(selected.stdout.splitlines()))

    def test_virtual_gpu_gets_software_vulkan(self):
        result = self.run_detector("GenuineIntel", ["0x1af4"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("lib32-vulkan-swrast", result.stdout.splitlines())

    def test_two_mesa_gpus_do_not_duplicate_packages(self):
        result = self.run_detector("AuthenticAMD", ["0x1002", "0x8086"])
        self.assertEqual(result.returncode, 0, result.stderr)
        packages = result.stdout.splitlines()
        self.assertEqual(len(packages), len(set(packages)))
        self.assertIn("vulkan-radeon", packages)
        self.assertIn("vulkan-intel", packages)

    def test_unknown_gpu_stops_install(self):
        result = self.run_detector("GenuineIntel", ["0xffff"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No supported GPU", result.stderr)


if __name__ == "__main__":
    unittest.main()
