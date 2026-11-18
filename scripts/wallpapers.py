#!/usr/bin/env python3
"""List wallpapers for DankShell's wallpaper switcher. Prints JSON:
{"current": "<path>", "theme": "<slug>", "items": [{"path", "name", "mine"}]}
"mine" = it belongs to the theme in use (the "This theme" filter). The rest
come from every other theme and from ~/GitDank/DankWallpapers.
Folders are the same ones `omarchy theme bg next` cycles through."""
import json, os
from pathlib import Path

HOME = Path.home()
STATE = HOME / ".local/state/omarchy"
USER_BGS = HOME / ".config/omarchy/backgrounds"
USER_THEMES = HOME / ".config/omarchy/themes"
SYS_THEMES = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "themes"
EXTRA = [HOME / "GitDank/DankWallpapers"]
IMAGES = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}


def images(d, depth=1):
    out = []
    try:
        for p in sorted(d.iterdir()):
            if p.is_file() and p.suffix.lower() in IMAGES:
                out.append(p.resolve())
            elif p.is_dir() and depth > 1 and not p.name.startswith("."):
                out += images(p, depth - 1)
    except OSError:
        pass
    return out


def theme_folders(slug):
    return [USER_BGS / slug, STATE / "current/theme/backgrounds"] if slug == current_theme else \
           [USER_BGS / slug, USER_THEMES / slug / "backgrounds", SYS_THEMES / slug / "backgrounds"]


try:
    current_theme = (STATE / "current/theme.name").read_text().strip()
except OSError:
    current_theme = ""
try:
    current = str((STATE / "current/background").resolve())
except OSError:
    current = ""

seen, items = set(), []


def add(paths, mine):
    for p in paths:
        if str(p) in seen:
            continue
        seen.add(str(p))
        items.append({"path": str(p), "name": p.stem.replace("-", " ").replace("_", " "), "mine": mine})


for d in theme_folders(current_theme):
    add(images(d), True)
slugs = set()
for root in (USER_BGS, USER_THEMES, SYS_THEMES):
    if root.is_dir():
        slugs |= {p.name for p in root.iterdir() if p.is_dir()}
for slug in sorted(slugs - {current_theme}):
    for d in theme_folders(slug):
        add(images(d), False)
for d in EXTRA:
    add(images(d, 2), False)

print(json.dumps({"current": current, "theme": current_theme, "items": items}))
