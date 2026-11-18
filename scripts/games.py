#!/usr/bin/env python3
"""List installed Steam games for DankShell's Game page. Prints JSON:
[{"appid", "name", "lastPlayed", "art"}], most recently played first.
Reads Steam's own files: libraryfolders.vdf, each library's appmanifest_*.acf
and the library art cache. Runtimes, Proton and redistributables are skipped."""
import json, re
from pathlib import Path

STEAM = Path.home() / ".local/share/Steam"
SKIP = re.compile(r"^(Proton|Steam Linux Runtime|Steamworks Common)", re.I)


def fields(text):
    return dict(re.findall(r'"(\w+)"\s+"([^"]*)"', text))


libs = [STEAM]
try:
    libs += [Path(p) for p in re.findall(r'"path"\s+"([^"]+)"', (STEAM / "steamapps/libraryfolders.vdf").read_text())]
except OSError:
    pass

seen, games = set(), []
for lib in libs:
    for acf in sorted((lib / "steamapps").glob("appmanifest_*.acf")):
        try:
            f = fields(acf.read_text(errors="replace"))
        except OSError:
            continue
        appid, name = f.get("appid", ""), f.get("name", "")
        if not appid or appid in seen or SKIP.match(name):
            continue
        seen.add(appid)
        cache = STEAM / "appcache/librarycache" / appid
        art = ""
        for pat in ("header.jpg", "*/header.jpg", "library_hero.jpg", "*/library_hero.jpg", "*.jpg"):
            hit = sorted(cache.glob(pat)) if cache.is_dir() else []
            if hit:
                art = str(hit[0])
                break
        games.append({"appid": appid, "name": name, "lastPlayed": int(f.get("LastPlayed", "0") or 0), "art": art})

games.sort(key=lambda g: -g["lastPlayed"])
print(json.dumps(games))
