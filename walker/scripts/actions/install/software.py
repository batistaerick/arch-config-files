#!/usr/bin/env python3
"""Walker software workflows. No package writes occur while listing or reviewing."""
import argparse
import gzip
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import time
import urllib.parse
import urllib.request

SCRIPT = Path(__file__).resolve()
WALKER = Path.home() / ".config/walker/bin/walker"
NAME = re.compile(r"[a-zA-Z0-9][a-zA-Z0-9@._+:-]*\Z")


def package_name(value):
    if not NAME.fullmatch(value) or ":" in value:
        raise ValueError("Invalid package name")
    return value


def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def text(args):
    return subprocess.check_output(args, text=True, timeout=20).strip()


def terminal(*args):
    subprocess.Popen(["kitty", "--class", "eitr-software", "--hold", "-e", *args], start_new_session=True)


def confirm(label):
    answer = subprocess.run([str(WALKER), "--dmenu", "--placeholder", label,
                             "--width", "600", "--minheight", "100"],
                            input="Cancel\nConfirm\n", text=True, capture_output=True)
    return answer.returncode == 0 and answer.stdout.strip() == "Confirm"


def data_dirs():
    """Eitr data directories: the user's XDG data home, then the system XDG data
    directories (the eitr-desktop package installs /usr/share/eitr)."""
    user = os.environ.get("XDG_DATA_HOME", "")
    directories = [Path(user) if os.path.isabs(user) else Path.home() / ".local/share"]
    system = os.environ.get("XDG_DATA_DIRS", "") or "/usr/local/share:/usr/share"
    directories += [Path(entry) for entry in system.split(":") if os.path.isabs(entry)]
    return [directory / "eitr" for directory in directories]


def data_file(name):
    """Find a distro data file: an installed copy, else this repository's checkout."""
    candidates = [directory / name for directory in data_dirs()]
    # In a checkout this script lives at walker/scripts/actions/install/.
    if len(SCRIPT.parents) > 4:
        candidates.append(SCRIPT.parents[4] / "distro" / name)
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(f"Eitr {name} is not installed. Install the eitr-desktop package "
                            "(see distro/README.md, Existing desktop).")


def catalog():
    return json.loads(data_file("software.json").read_text())


def installer_url(name):
    url = json.loads(data_file("installers.json").read_text())[name]
    if not url.startswith("https://"):
        raise ValueError("Installer must use HTTPS")
    return url


def recipes(group):
    return [{"id": key, **value} for key, value in catalog()[group].items()]


def require_no_pending_updates():
    """Refuse installs that would also perform an unsnapshotted system upgrade.

    Partial upgrades (-Sy without -u) are unsupported on Arch, so installs only
    proceed once System Update has brought the system up to date.
    """
    if not shutil.which("checkupdates"):
        raise RuntimeError("checkupdates (pacman-contrib) is required to install safely. "
                           "Run System → Update → System Update, then install pacman-contrib.")
    # checkupdates syncs a private database copy: 0 = updates, 2 = none, 1 = error.
    result = subprocess.run(["checkupdates"], capture_output=True, text=True, timeout=120)
    if result.returncode == 0:
        count = len(result.stdout.splitlines())
        raise RuntimeError(f"{count} system update(s) pending. Run System → Update → System Update first, "
                           "so upgrades get a recovery snapshot, then install again.")
    if result.returncode != 2:
        raise RuntimeError("Could not check for pending updates: " + (result.stderr.strip() or "checkupdates failed"))


def install(source, packages):
    packages = list(dict.fromkeys(package_name(name) for name in packages))
    if not packages:
        raise ValueError("Select at least one package")
    if source == "pacman":
        require_no_pending_updates()
        # Nothing is pending, so -u only refreshes the databases; pacman still
        # lists every transaction before asking for confirmation.
        run(["sudo", "pacman", "-Syu", "--needed", "--", *packages])
    elif source == "aur":
        # Never execute AUR builds as root or suppress yay's review prompts.
        if os.geteuid() == 0:
            raise RuntimeError("AUR builds must run as a normal user")
        run(["yay", "-S", "--needed", "--", *packages])
    else:
        raise ValueError("Unknown package source")


def review(source, name):
    name = package_name(name)
    if source == "pacman":
        print(text(["pacman", "-Si", "--", name]))
        print("\nOfficial prebuilt package metadata; there is no local AUR build to execute.")
        run(["xdg-open", "https://archlinux.org/packages/?q=" + urllib.parse.quote(name)])
    elif source == "aur":
        # RPC resolves split packages to their actual PackageBase. Nothing is sourced.
        url = "https://aur.archlinux.org/rpc/v5/info?arg[]=" + urllib.parse.quote(name)
        with urllib.request.urlopen(url, timeout=10) as response:
            data = json.load(response)
        if not data.get("results"):
            raise ValueError("AUR package not found")
        base = package_name(data["results"][0]["PackageBase"])
        run(["xdg-open", "https://aur.archlinux.org/cgit/aur.git/tree/?h=" + urllib.parse.quote(base)])
        print("Opened the complete build repository: review PKGBUILD, .install files and patches.")
    else:
        raise ValueError("Unknown package source")


def resolve_app(path):
    path = Path(path).resolve(strict=True)
    roots = [Path.home() / ".local/share/applications", Path("/usr/share/applications"),
             Path("/usr/local/share/applications"), Path.home() / ".local/share/flatpak/app",
             Path("/var/lib/flatpak/app")]
    if path.suffix != ".desktop" or not any(path.is_relative_to(root) for root in roots):
        raise ValueError("Unsupported application launcher path")
    for line in path.read_text().splitlines():
        if line.startswith("X-Flatpak="):
            app = line.split("=", 1)[1].strip()
            if not re.fullmatch(r"[A-Za-z0-9_.-]+", app):
                raise ValueError("Invalid Flatpak application ID")
            return "flatpak", app
    candidates = [path]
    if path.is_relative_to(roots[0]):
        candidates.extend(root / path.name for root in roots[1:])
    for candidate in candidates:
        result = subprocess.run(["pacman", "-Qoq", "--", str(candidate)],
                                capture_output=True, text=True, timeout=5)
        owners = result.stdout.splitlines()
        if result.returncode == 0 and len(owners) == 1:
            return "pacman", package_name(owners[0])
    raise ValueError("This launcher is not owned by an installed package. No files were removed.")


def uninstall(path):
    source, name = resolve_app(path)
    if not confirm(f"Uninstall {name}? The package may contain multiple apps."):
        return
    terminal("python3", str(SCRIPT), "remove", source, name)


def remove(source, name):
    if source == "pacman":
        # Plain -R preserves backup configs; never recursively remove dependents.
        run(["sudo", "pacman", "-R", "--", package_name(name)])
    elif source == "flatpak":
        if not re.fullmatch(r"[A-Za-z0-9_.-]+", name):
            raise ValueError("Invalid Flatpak ID")
        run(["flatpak", "uninstall", "--", name])
    else:
        raise ValueError("Unsupported uninstall source")


def recipe(group, identifier):
    item = catalog()[group][identifier]
    if item["source"] == "flatpak":
        for remote in item.get("runtime_remotes", []):
            run(["flatpak", "remote-add", "--user", "--if-not-exists", remote["name"], remote["url"]])
        run(["flatpak", "remote-add", "--user", "--if-not-exists", item["remote"], item["url"]])
        run(["flatpak", "install", "--user", "--or-update", item["remote"], *item["packages"]])
    else:
        if item["packages"]:
            install("aur" if item["source"] == "aur" else "pacman", item["packages"])
        if item["source"] == "managed":
            run(["bash", str(SCRIPT.with_name("development.sh")), identifier])


def package_picker(source):
    if source == "pacman":
        names = text(["pacman", "-Slq"]).splitlines()
    elif source == "aur":
        print("Loading AUR package names…", flush=True)
        with urllib.request.urlopen("https://aur.archlinux.org/packages.gz", timeout=30) as response:
            names = gzip.decompress(response.read()).decode().splitlines()
    else:
        raise ValueError("Unknown package source")
    names = sorted({name for name in names if NAME.fullmatch(name) and ":" not in name})
    if not names:
        raise ValueError("No package names available; check your package databases/network")
    review_command = shlex.join(["python3", str(SCRIPT), "review", source]) + " {}"
    result = subprocess.run(
        ["fzf", "--multi", "--layout=reverse", "--border", "--prompt", source.upper() + " > ",
         "--header", "Type to search · Tab select · Enter install · Ctrl+B review · Esc cancel",
         "--bind", "tab:toggle+down,shift-tab:toggle+up,ctrl-b:execute(" + review_command + ")"],
        input="\n".join(names) + "\n", text=True, stdout=subprocess.PIPE)
    if result.returncode in (1, 130):
        return
    if result.returncode != 0:
        raise RuntimeError("Package picker failed")
    selected = result.stdout.splitlines()
    if selected:
        install(source, selected)


def gaming(identifier):
    if identifier == "steam":
        if shutil.which("steam"):
            subprocess.Popen(["steam"], start_new_session=True)
            return
    elif identifier == "geforcenow":
        if shutil.which("flatpak"):
            result = subprocess.run(["flatpak", "info", "com.nvidia.geforcenow"],
                                    capture_output=True, timeout=10)
            if result.returncode == 0:
                subprocess.Popen(["flatpak", "run", "com.nvidia.geforcenow"], start_new_session=True)
                return
    else:
        raise ValueError("Unknown gaming app")
    terminal("python3", str(SCRIPT), "gaming-install", identifier)


def gaming_install(identifier):
    if identifier not in ("steam", "geforcenow"):
        raise ValueError("Unknown gaming app")
    if identifier == "geforcenow" and not shutil.which("flatpak"):
        install("pacman", ["flatpak"])
    recipe("gaming", identifier)


JSON_ACTIONS = {"recipes"}


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["recipes", "installer", "install", "launch", "review", "uninstall", "remove", "recipe", "recipe-launch", "gaming", "gaming-install", "picker", "picker-launch"])
    parser.add_argument("args", nargs="*")
    return parser.parse_args()


def main(options):
    args = options.args
    if options.action == "installer":
        print(installer_url(args[0]))
    elif options.action == "recipes":
        print(json.dumps(recipes(args[0])))
    elif options.action == "install":
        install(args[0], args[1:])
    elif options.action == "launch":
        terminal("python3", str(SCRIPT), "install", *args)
    elif options.action == "review":
        review(*args)
    elif options.action == "uninstall":
        # The initiating Walker view closes before showing the confirmation.
        time.sleep(0.15)
        uninstall(args[0])
    elif options.action == "remove":
        remove(*args)
    elif options.action == "recipe":
        recipe(*args)
    elif options.action == "recipe-launch":
        terminal("python3", str(SCRIPT), "recipe", *args)
    elif options.action == "gaming":
        gaming(*args)
    elif options.action == "gaming-install":
        gaming_install(*args)
    elif options.action == "picker":
        package_picker(*args)
    elif options.action == "picker-launch":
        terminal("python3", str(SCRIPT), "picker", *args)


if __name__ == "__main__":
    options = parse_arguments()
    try:
        main(options)
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        if options.action in JSON_ACTIONS:
            # Menus render this row instead of silently showing nothing.
            print(json.dumps([{"label": str(error), "error": True}]))
        else:
            subprocess.run(["notify-send", "Eitr software", str(error)])
        sys.exit(1)
