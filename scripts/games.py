#!/usr/bin/env python3
"""List installed Steam games for DankShell's Game page. Prints JSON:
[{"appid", "name", "lastPlayed", "art", "mods"}], most recently played first.
Reads Steam's own files: libraryfolders.vdf, each library's appmanifest_*.acf
and the library art cache. Runtimes, Proton and redistributables are skipped.
"mods" lists r2modman profiles for the game (~/.config/r2modmanPlus-local/<Game>/
profiles/<Profile>), each with the Steam launch arguments r2modman's own
"Start modded" sends (BepInEx doorstop + --r2profile for linux_wrapper.sh).
"launcher" (GTA: mods) is a DankShell script that does the modded launch."""
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


R2 = Path.home() / ".config/r2modmanPlus-local"


def squash(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())


def r2_profiles(game_name):
    """r2modman profiles for a game whose folder name matches the Steam name."""
    out = []
    if not R2.is_dir():
        return out
    for gdir in R2.iterdir():
        if squash(gdir.name) != squash(game_name) or not (gdir / "linux_wrapper.sh").is_file():
            continue
        for prof in sorted((gdir / "profiles").glob("*")):
            pre = prof / "BepInEx/core/BepInEx.Preloader.dll"
            start = prof / "start_game_bepinex.sh"
            if not pre.is_file():
                continue
            try:
                v4 = "--doorstop-enabled" in start.read_text(errors="replace")
            except OSError:
                v4 = True
            args = (["--doorstop-enabled", "true", "--doorstop-target-assembly", str(pre)] if v4
                    else ["--doorstop-enable", "true", "--doorstop-target", str(pre)])
            args += ["--r2profile", prof.name]
            if (prof / "unstripped_corlib").is_dir():
                args += (["--doorstop-mono-dll-search-path-override"] if v4 else ["--doorstop-dll-search-override"]) + [str(prof / "unstripped_corlib")]
            out.append({"profile": prof.name, "args": args})
    return out


# Games with their own modded launch script in DankShell's scripts/.
LAUNCHERS = {
    "3240220": ("mods", Path(__file__).resolve().parent / "gta-modded", Path.home() / ".local/bin/modloader"),
}

for g in games:
    g["mods"] = r2_profiles(g["name"])
    hit = LAUNCHERS.get(g["appid"])
    if hit and hit[1].is_file() and hit[2].is_file():
        g["launcher"] = {"name": hit[0], "script": str(hit[1])}

games.sort(key=lambda g: -g["lastPlayed"])
print(json.dumps(games))
