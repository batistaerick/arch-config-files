from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

DISTRO = Path(__file__).resolve().parents[1]
PACKAGE = DISTRO / "pkg/eitr-desktop"
VERSION = re.compile(r"0\.r[0-9]+\.g[0-9a-f]{7,}")


def manifest(name):
    return [line.strip() for line in (DISTRO / name).read_text().splitlines()
            if line.strip() and not line.lstrip().startswith("#")]


def bash_has_mapfile():
    return subprocess.run(["bash", "-c", "mapfile -t x < /dev/null"], capture_output=True).returncode == 0


@unittest.skipUnless(shutil.which("git") and bash_has_mapfile(), "needs git and bash 4+")
class DesktopPackageTests(unittest.TestCase):
    def source_pkgbuild(self, expression):
        script = f'startdir="$1"; source "$1/PKGBUILD"; {expression}'
        result = subprocess.run(["bash", "-c", script, "pkgbuild", str(PACKAGE)],
                                capture_output=True, text=True, check=True)
        return result.stdout.splitlines()

    def test_depends_are_official_desktop_packages_without_system_choices(self):
        depends = self.source_pkgbuild('printf "%s\\n" "${depends[@]}"')
        system_choices = {"base", "base-devel", "linux", "linux-firmware"}
        self.assertEqual(depends, [name for name in manifest("packages.txt") if name not in system_choices])
        hardware = {name for path in (DISTRO / "hardware").glob("*.txt") for name in manifest(path.relative_to(DISTRO))}
        self.assertFalse(hardware & set(depends))
        self.assertFalse(set(manifest("apps.txt")) & set(depends) - set(manifest("packages.txt")))
        aur = set(manifest("aur-packages.txt")) | set(manifest("aur-apps.txt"))
        self.assertFalse(aur & set(depends))

    def test_aur_desktop_packages_are_documented_as_optional(self):
        optdepends = self.source_pkgbuild('printf "%s\\n" "${optdepends[@]}"')
        self.assertEqual([entry.split(":", 1)[0] for entry in optdepends], manifest("aur-packages.txt"))

    def test_version_comes_from_git(self):
        (version,) = self.source_pkgbuild('printf "%s\\n" "$pkgver"')
        self.assertRegex(version, VERSION)

    def test_package_paths_match_consumers(self):
        pkgbuild = (PACKAGE / "PKGBUILD").read_text()
        self.assertIn('"$pkgdir/usr/lib/eitr/eitr-system"', pkgbuild)
        self.assertIn('"$pkgdir/usr/bin/eitr-config"', pkgbuild)
        self.assertIn('"$pkgdir/usr/lib/systemd/user"', pkgbuild)
        self.assertIn("git -C \"$_repo\" archive", pkgbuild)
        for name in ("software.json", "installers.json", "RECOVERY.md", "system-update-policy.conf"):
            self.assertIn(f"distro/{name}", pkgbuild)
        self.assertIn("pkgdir/usr/share/eitr", pkgbuild)
        # makepkg would write a pkgver() result back into the tracked file.
        self.assertNotRegex(pkgbuild, r"(?m)^pkgver\(\)")
        subprocess.run(["bash", "-n", str(PACKAGE / "eitr-desktop.install")], check=True)

    def test_exported_tree_needs_a_valid_version_stamp(self):
        script = PACKAGE / "source-version.sh"
        with tempfile.TemporaryDirectory() as directory:
            stamp = Path(directory) / "distro/pkg/eitr-desktop/source-version"
            missing = subprocess.run(["bash", str(script), directory], capture_output=True, text=True)
            self.assertNotEqual(missing.returncode, 0)
            stamp.parent.mkdir(parents=True)
            stamp.write_text("0.r12.gabcdef1\n")
            result = subprocess.run(["bash", str(script), directory], capture_output=True, text=True, check=True)
            self.assertEqual(result.stdout, "0.r12.gabcdef1\n")
            stamp.write_text("1.0; rm -rf /\n")
            invalid = subprocess.run(["bash", str(script), directory], capture_output=True, text=True)
            self.assertNotEqual(invalid.returncode, 0)


if __name__ == "__main__":
    unittest.main()
