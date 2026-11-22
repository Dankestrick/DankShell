#!/usr/bin/env python3
"""Find an Epic Games launcher and its installed games for DankShell's Games
window. Prints JSON: {"launcher": {"name", "desktop"} | null, "games": [...]}.
The Epic tab only shows when a launcher is found.

Launchers: any desktop entry whose name says Epic (the official Linux one when
it ships), Heroic, or Legendary. Games come from Legendary's installed.json
(Heroic keeps its own copy): [{"app", "name", "via"}]."""
import json, re
from pathlib import Path

HOME = Path.home()
APP_DIRS = [HOME / ".local/share/applications", Path("/usr/share/applications"),
            HOME / ".local/share/flatpak/exports/share/applications",
            Path("/var/lib/flatpak/exports/share/applications")]


def desktop_name(path):
    try:
        for line in path.read_text(errors="replace").splitlines():
            if line.startswith("Name="):
                return line[5:].strip()
    except OSError:
        pass
    return path.stem


launcher = None
for d in APP_DIRS:
    if not d.is_dir():
        continue
    for f in sorted(d.glob("*.desktop")):
        n = desktop_name(f)
        if re.search(r"\bepic\b|heroic|legendary", f.stem + " " + n, re.I):
            launcher = {"name": n, "desktop": f.stem}
            break
    if launcher:
        break

games = []
for via, path in (("heroic", HOME / ".config/heroic/legendaryConfig/legendary/installed.json"),
                  ("legendary", HOME / ".config/legendary/installed.json")):
    try:
        data = json.loads(path.read_text())
    except (OSError, ValueError):
        continue
    for app, g in (data or {}).items():
        if any(x["app"] == app for x in games):
            continue
        games.append({"app": app, "name": g.get("title") or app, "via": via})

print(json.dumps({"launcher": launcher, "games": sorted(games, key=lambda g: g["name"].lower())}))
