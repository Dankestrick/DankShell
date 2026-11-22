#!/usr/bin/env python3
"""Find the game launchers you have installed (besides Steam, which has its own
tab) for DankShell's Games window. Each one found gets a tab. Prints JSON:
[{"id", "name", "icon", "desktop", "games": [{"name", "cmd": [...], "store"}]}]

A launcher counts as installed when its desktop entry is there (native or
Flatpak). Games are listed where the launcher keeps a readable list:
  Heroic     Epic / GOG / Amazon installs     heroic://launch/<runner>/<app>
  Lutris     its game library (installed)     lutris lutris:rungameid/<id>
  Legendary  Epic installs                    legendary launch <app>
  Prism      Minecraft instances              prismlauncher -l <instance>
The rest get an Open button only."""
import json, re, sqlite3
from pathlib import Path

HOME = Path.home()
VAR = HOME / ".var/app"
APP_DIRS = [HOME / ".local/share/applications", Path("/usr/share/applications"),
            HOME / ".local/share/flatpak/exports/share/applications",
            Path("/var/lib/flatpak/exports/share/applications")]

# id, tab name, icon, desktop-entry pattern (file name or Name=)
LAUNCHERS = [
    ("epic", "Epic", "storefront", r"epic.?games|^epic\b"),
    ("heroic", "Heroic", "storefront", r"heroic"),
    ("lutris", "Lutris", "sports_esports", r"lutris"),
    ("legendary", "Legendary", "storefront", r"legendary|rare\b"),
    ("bottles", "Bottles", "wine_bar", r"usebottles|^bottles"),
    ("itch", "itch.io", "sports_esports", r"itch\.io|^io\.itch|^itch$"),
    ("prism", "Minecraft", "deployed_code", r"prismlauncher|polymc|multimc|minecraft"),
    ("atlauncher", "ATLauncher", "deployed_code", r"atlauncher"),
    ("retroarch", "RetroArch", "videogame_asset", r"retroarch"),
    ("esde", "ES-DE", "videogame_asset", r"\bes-de\b|es_de|emulationstation"),
    ("minigalaxy", "Minigalaxy", "storefront", r"minigalaxy"),
    ("faugus", "Faugus", "sports_esports", r"faugus"),
    ("osu", "osu!", "sports_esports", r"\bosu"),
    ("geforcenow", "GeForce NOW", "cloud", r"geforce.?now"),
]


def entries():
    out = []
    for d in APP_DIRS:
        if not d.is_dir():
            continue
        for f in sorted(d.glob("*.desktop")):
            name = f.stem
            try:
                for line in f.read_text(errors="replace").splitlines():
                    if line.startswith("Name="):
                        name = line[5:].strip()
                        break
            except OSError:
                pass
            out.append((f.stem, name))
    return out


def first(*paths):
    for p in paths:
        if p.exists():
            return p
    return None


def read_json(p):
    try:
        return json.loads(p.read_text())
    except (OSError, ValueError, AttributeError):
        return None


def heroic_games():
    games = []
    base = first(HOME / ".config/heroic", VAR / "com.heroicgameslauncher.hgl/config/heroic")
    if not base:
        return games
    stores = [("legendary", "Epic", base / "legendaryConfig/legendary/installed.json"),
              ("gog", "GOG", base / "gog_store/installed.json"),
              ("nile", "Amazon", base / "nile_config/nile/installed.json")]
    for runner, store, path in stores:
        data = read_json(path)
        if isinstance(data, dict) and "installed" in data:
            data = data["installed"]
        items = data.items() if isinstance(data, dict) else ((None, g) for g in (data or []))
        for key, g in items:
            if not isinstance(g, dict):
                continue
            app = g.get("app_name") or g.get("appName") or g.get("id") or key
            name = g.get("title") or g.get("name") or app
            if app:
                games.append({"name": name, "store": store, "cmd": ["xdg-open", f"heroic://launch/{runner}/{app}"]})
    return games


def lutris_games():
    db = first(HOME / ".local/share/lutris/pga.db", VAR / "net.lutris.Lutris/data/lutris/pga.db")
    if not db:
        return []
    try:
        con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
        rows = con.execute("select id, name, runner from games where installed = 1 order by lastplayed desc").fetchall()
        con.close()
    except sqlite3.Error:
        return []
    return [{"name": n, "store": r or "", "cmd": ["lutris", f"lutris:rungameid/{i}"]} for i, n, r in rows]


def legendary_games():
    data = read_json(HOME / ".config/legendary/installed.json") or {}
    return [{"name": g.get("title") or app, "store": "Epic", "cmd": ["legendary", "launch", app]}
            for app, g in data.items() if isinstance(g, dict)]


def prism_games():
    base = first(HOME / ".local/share/PrismLauncher/instances", VAR / "org.prismlauncher.PrismLauncher/data/PrismLauncher/instances")
    if not base:
        return []
    out = []
    for cfg in sorted(base.glob("*/instance.cfg")):
        name = cfg.parent.name
        try:
            m = re.search(r"^name=(.+)$", cfg.read_text(errors="replace"), re.M)
            if m:
                name = m.group(1).strip()
        except OSError:
            pass
        out.append({"name": name, "store": "Minecraft", "cmd": ["prismlauncher", "-l", cfg.parent.name]})
    return out


GAMES = {"heroic": heroic_games, "lutris": lutris_games, "legendary": legendary_games, "prism": prism_games}

found, have = [], entries()
for lid, tab, icon, pat in LAUNCHERS:
    rx = re.compile(pat, re.I)
    hit = next(((stem, name) for stem, name in have
                if not re.search(r"steam|moonlight|sunshine", stem + " " + name, re.I) and (rx.search(stem) or rx.search(name))), None)
    if not hit:
        continue
    games = GAMES[lid]() if lid in GAMES else []
    found.append({"id": lid, "name": tab, "icon": icon, "desktop": hit[0], "app": hit[1],
                  "games": sorted(games, key=lambda g: g["name"].lower()) if lid != "lutris" else games})

print(json.dumps(found))
