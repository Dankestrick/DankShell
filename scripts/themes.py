#!/usr/bin/env python3
"""List Omarchy themes for DankShell's theme switcher. Prints JSON:
{"current": "<slug>", "themes": [{"slug", "name", "colors": {...}, "wallpaper": "<path or ''>"}]}
The wallpaper is the one Omarchy remembers for that theme (the same one
`omarchy theme set` will put up), else the theme's first image."""
import json, os, subprocess, tomllib
from pathlib import Path

HOME = Path.home()
STATE = HOME / ".local/state/omarchy"
USER_THEMES = HOME / ".config/omarchy/themes"
SYS_THEMES = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "themes"
USER_BGS = HOME / ".config/omarchy/backgrounds"
IMAGES = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"}
KEYS = ["background", "foreground", "accent", "red", "yellow", "green", "cyan", "blue", "magenta"]


def theme_dir(slug):
    for root in (USER_THEMES, SYS_THEMES):
        d = root / slug
        if d.is_dir():
            return d
    return None


def images(*dirs):
    out = []
    for d in dirs:
        if d and d.is_dir():
            out += [p for p in d.iterdir() if p.is_file() and p.suffix.lower() in IMAGES]
    return sorted(out, key=lambda p: str(p))


def wallpaper(slug, d):
    pool = images(USER_BGS / slug, d / "backgrounds")
    remembered = STATE / "theme-backgrounds" / slug
    if remembered.is_file():
        name = Path(remembered.read_text().strip()).name
        for p in pool:
            if p.name == name:
                return str(p)
    return str(pool[0]) if pool else ""


# colorN numbering used by newer themes without named colors
ANSI = {"red": "color1", "green": "color2", "yellow": "color3", "blue": "color4", "magenta": "color5", "cyan": "color6"}


def load(path):
    try:
        return tomllib.loads(path.read_text())
    except (OSError, tomllib.TOMLDecodeError):
        return {}


def read_colors(d):
    """Named colors from colors.toml; colorN numbers; else older themes' alacritty.toml."""
    data = load(d / "colors.toml")
    colors = {k: data[k] for k in KEYS if isinstance(data.get(k), str)}
    for name, num in ANSI.items():
        if name not in colors and isinstance(data.get(num), str):
            colors[name] = data[num]
    ala = load(d / "alacritty.toml").get("colors", {})
    prim, norm = ala.get("primary", {}), ala.get("normal", {})
    for k in ("background", "foreground"):
        if k not in colors and isinstance(prim.get(k), str):
            colors[k] = prim[k]
    for k in ANSI:
        if k not in colors and isinstance(norm.get(k), str):
            colors[k] = norm[k]
    colors = {k: v.replace("0x", "#") for k, v in colors.items()}
    colors["mode"] = data.get("mode", "dark")
    return colors


def main():
    names = subprocess.run(["omarchy", "theme", "list"], capture_output=True, text=True, timeout=10).stdout.splitlines()
    current = ""
    try:
        current = (STATE / "current/theme.name").read_text().strip()
    except OSError:
        pass
    themes = []
    for name in names:
        name = name.strip()
        if not name:
            continue
        slug = name.lower().replace(" ", "-")
        d = theme_dir(slug)
        if not d:
            continue
        colors = read_colors(d)
        themes.append({"slug": slug, "name": name, "colors": colors, "wallpaper": wallpaper(slug, d)})
    print(json.dumps({"current": current, "themes": themes}))


main()
