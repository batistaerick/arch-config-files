#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys
import tomllib
import hashlib
from PIL import Image

home = Path.home()
mode = sys.argv[1] if len(sys.argv) > 1 else "wallpaper"
cache = Path(os.environ.get("XDG_CACHE_HOME", str(home / ".cache")))
config = home / ".config"
def preview_url(path):
    if path.suffix.lower() != ".webp":
        return path.as_uri()
    info = path.stat()
    key = hashlib.sha256(f"{path}:{info.st_mtime_ns}:{info.st_size}".encode()).hexdigest()
    directory = cache / "desktop-appearance"
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / f"{key}.png"
    if not target.exists():
        with Image.open(path) as image:
            image.thumbnail((1536, 950))
            image.save(target, "PNG")
    return target.as_uri()
def read_current(name):
    try:
        return (cache / name).read_text().strip()
    except OSError:
        return ""

entries = []
if mode == "theme":
    current = read_current("current-theme")
    for directory in sorted((config / "themes").iterdir()):
        image = directory / "preview.png"
        if directory.is_dir() and image.is_file():
            entries.append({"name": directory.name, "value": directory.name,
                            "image": image.as_uri(), "current": directory.name == current})
else:
    current = read_current("current-wallpaper")
    directory = config / "theme/current/backgrounds"
    import re
    def natural(path):
        return [int(part) if part.isdigit() else part.lower()
                for part in re.split(r"(\d+)", path.name)]
    for image in sorted(directory.rglob("*"), key=natural):
        if image.is_file() and image.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}:
            entries.append({"name": image.name, "value": str(image),
                            "image": preview_url(image), "current": str(image) == current})
try:
    palette = tomllib.loads((config / "theme/current/colors.toml").read_text())
except (OSError, ValueError):
    palette = {}
print(json.dumps({"items": entries, "accent": palette.get("accent", "#cdd6f4"),
                  "foreground": palette.get("foreground", "#ffffff")}))
