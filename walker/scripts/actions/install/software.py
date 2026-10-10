#!/usr/bin/env python3
"""Walker software workflows. No package writes occur while listing or reviewing."""
import argparse
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
CATALOG = Path.home() / ".local/share/eitr/software.json"
if not CATALOG.exists():
    CATALOG = SCRIPT.parents[4] / "distro/software.json"
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


def catalog():
    return json.loads(CATALOG.read_text())


def recipes(group):
    return [{"id": key, **value} for key, value in catalog()[group].items()]


def search(source, query):
    query = query.strip()
    if len(query) < 2:
        return [{"name": "", "description": "Type at least two characters to search packages"}]
    if len(query) > 120:
        return []
    if source == "pacman":
        # pacman searches descriptions as well as names using a regexp.
        result = subprocess.run(["pacman", "-Ss", "--color", "never", "--", re.escape(query)],
                                capture_output=True, text=True, timeout=10)
        if result.returncode not in (0, 1):
            raise RuntimeError(result.stderr.strip())
        rows = []
        for line in result.stdout.splitlines():
            if line and not line[0].isspace():
                repository, _, rest = line.partition("/")
                name = rest.split()[0] if rest else ""
                if NAME.fullmatch(name):
                    rows.append({"name": name, "description": repository + " · " + rest})
            elif rows:
                rows[-1]["description"] += " · " + line.strip()
        return rows[:150]
    if source != "aur":
        raise ValueError("Unknown package source")
    cache_dir = Path.home() / ".cache/eitr-package-search"
    import hashlib
    cache_file = cache_dir / (hashlib.sha256(query.encode()).hexdigest() + ".json")
    try:
        if time.time() - cache_file.stat().st_mtime < 300:
            return json.loads(cache_file.read_text())
    except (OSError, ValueError):
        pass
    url = "https://aur.archlinux.org/rpc/v5/search/" + urllib.parse.quote(query, safe="") + "?by=name-desc"
    with urllib.request.urlopen(url, timeout=3) as response:
        data = json.load(response)
    if data.get("type") == "error":
        raise RuntimeError(data.get("error", "AUR search failed"))
    rows = [{"name": package_name(row["Name"]), "description": "AUR · " + (row.get("Description") or "")}
            for row in data.get("results", [])[:150]]
    cache_dir.mkdir(parents=True, exist_ok=True)
    cache_file.write_text(json.dumps(rows))
    return rows


def install(source, packages):
    packages = list(dict.fromkeys(package_name(name) for name in packages))
    if not packages:
        raise ValueError("Select at least one package")
    if source == "pacman":
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
        run(["flatpak", "remote-add", "--user", "--if-not-exists", item["remote"], item["url"]])
        run(["flatpak", "install", "--user", item["remote"], *item["packages"]])
    else:
        if item["packages"]:
            install("aur" if item["source"] == "aur" else "pacman", item["packages"])
        if item["source"] == "managed":
            run(["bash", str(SCRIPT.with_name("development.sh")), identifier])


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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["search", "recipes", "installer", "install", "launch", "review", "uninstall", "remove", "recipe", "recipe-launch", "gaming", "gaming-install"])
    parser.add_argument("args", nargs="*")
    options = parser.parse_args()
    args = options.args
    if options.action == "search":
        print(json.dumps(search(args[0], args[1] if len(args) > 1 else "")))
    elif options.action == "installer":
        url = json.loads(CATALOG.with_name("installers.json").read_text())[args[0]]
        if not url.startswith("https://"):
            raise ValueError("Installer must use HTTPS")
        print(url)
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


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        if "search" in sys.argv or "recipes" in sys.argv:
            print(json.dumps([{"name": "", "description": "Search unavailable; check network/package databases"}]))
        else:
            subprocess.run(["notify-send", "Eitr software", str(error)])
        sys.exit(1)
