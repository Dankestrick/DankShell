#!/usr/bin/env python3
"""List installed Steam games for DankShell's Game page. Prints JSON:
[{"appid", "name", "lastPlayed", "art", "mods"}], most recently played first.
Reads Steam's own files: libraryfolders.vdf, each library's appmanifest_*.acf
and the library art cache. Runtimes, Proton and redistributables are skipped.
"mods" lists r2modman profiles for the game (~/.config/r2modmanPlus-local/<Game>/
profiles/<Profile>), each with the Steam launch arguments r2modman's own
"Start modded" sends (BepInEx doorstop + --r2profile for linux_wrapper.sh).
"launcher" is your own launch script for a game, set in ~/.config/dankshell/launchers.json:
  {"<appid>": {"name": "Button label", "script": "~/path/to/script"}}"""
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


# Your own launch scripts, per Steam app id (~/.config/dankshell/launchers.json).
def launchers():
    try:
        data = json.loads((Path.home() / ".config/dankshell/launchers.json").read_text())
    except (OSError, ValueError):
        return {}
    out = {}
    for appid, v in (data.items() if isinstance(data, dict) else []):
        if not isinstance(v, dict) or not isinstance(v.get("script"), str):
            continue
        script = Path(v["script"]).expanduser()
        if script.is_file():
            out[str(appid)] = {"name": str(v.get("name") or "Modded")[:24], "script": str(script)}
    return out


LAUNCHERS = launchers()
for g in games:
    g["mods"] = r2_profiles(g["name"])
    if g["appid"] in LAUNCHERS:
        g["launcher"] = LAUNCHERS[g["appid"]]

games.sort(key=lambda g: -g["lastPlayed"])
print(json.dumps(games))
