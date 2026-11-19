# DankShell

A dynamic island shell for Omarchy. One pill at the top of each screen that grows when you hover it and opens a dashboard when you click it.

## Where things live

| Folder | What's in it | Open it when you want to... |
|---|---|---|
| `config/` | `Sizes.qml`, `Motion.qml`, `Theme.qml` | change a size, a speed, a color, a font |
| `services/` | where data comes from (time, music, workspaces...) | change what the island knows |
| `components/` | small pieces used everywhere (`Pill`, `Icon`) | change how a basic piece looks |
| `modules/island/` | the island and its states (`Hover`, `Dashboard`; the clock lives in `Island.qml`) | change what the island shows |
| `modules/pages/` | one file per dashboard page | change one page |
| `modules/settings/` | one file per settings section | change a settings screen |

`Bar.qml` is only the doorway Omarchy opens. `qmldir` lists every piece so any file can use any other.

## On and off

```sh
scripts/dankshell on       # DankShell is the bar and runs your plugins
scripts/dankshell off      # stock Omarchy bar, plugins back with Omarchy
scripts/dankshell status
scripts/dankshell install  # copy the repo into Omarchy's plugin folder
```

Your plugins with a page are listed in `config/Plugins.js`.

## Try it

```sh
rsync -a --delete --exclude .git ~/GitDank/DankShell/ ~/.config/omarchy/plugins/io.github.dankestrick.dankshell/
```

Then `omarchy restart shell`. The shell keeps the old copy of a bar until it restarts.

Turn it on: set `"bar": { "id": "io.github.dankestrick.dankshell" }` in `~/.config/omarchy/shell.json`.
Back to the stock bar: set it to `"omarchy.bar"`.

## Credits

Design numbers from saneAspect's videos. Island ideas from ZenoShell (MIT).

## Newer pieces

- **Center window** (`modules/center/`): opens as **Plugins** (puzzle button; every installed plugin: Running, Not running, Omarchy; use each right there: its page, its real dropdown placed in the window, Open for its own window, Turn on when off; `services/Installed.qml` + `scripts/plugins.py`), **Settings** (gear), or **Notifications / Sound**. `qs ipc -p /usr/share/omarchy/shell call dankshell plugins|settings|center <page>`.
- **Settings** (`modules/settings/`, `config/SettingsList.js`, `services/Settings.qml`): sliders that reshape the island live; saved in `~/.config/dankshell/settings.json`.
- **Wallpapers** (`modules/island/WallpaperSwitcher.qml`): the island turns into a carousel. `... call dankshell walls`.
- **Plugins tab + top row**: every plugin (your page plugins and every bar widget, via `services/WidgetHost.qml` + `config/Widgets.js`) is listed in the Center window's Plugins tab. Pin any of them (Pin button on its page, or Settings › Top row, where arrows set the order) and it joins the island's top row next to themes/wallpapers/settings: page plugins open inside the island like tabs, widgets show their real icon and dropdown. `omarchy-shell shell summon <id>` opens one. `... call dankshell widgets` lists what started.
- **Date** under the dashboard clock opens the Journal.
- **Game mode** (`scripts/gamemode on|off|toggle|status`): stay awake, notifications silenced, animations off, night light off, performance power profile; off puts each back. Tile on Home, or `... call dankshell gamemode`.
- **Device button** in the dashboard top row (between wallpapers and plugins) opens the Device window on the last page you used there (Games, Camera, System, Sound, Notifications). **Right-click** anywhere in the Center window goes back to the dashboard (or just closes it when a key opened it).
- **Keys** (in `~/.config/hypr/bindings.lua`, the "dankshell" block): Super+Alt+A dashboard, Super+N notifications, Super+U plugins, Super+Alt+I settings, Super+Alt+Y games. Same key again closes.
- **Plugins window extras**: "All plugins" grid with live status (`services/Status.qml`), status in the sidebar, a Background group for service-only plugins, dropdowns get the whole right side.
- **Games** (`modules/pages/Game.qml`, `scripts/games.py`): Game Mode, DualSense status, your Steam games (most recent first), Play launches through Steam and can turn Game Mode on. Games with an r2modman profile (Valheim) play modded with the same launch r2modman's "Start modded" sends; their card has Modded, Vanilla and Mods (opens r2modman) buttons. Every card has the same launch buttons; the lit one is what the big Play does, right-click a button to make it the default (Settings.v.gameDefaults). GTA V Enhanced plays with mods (`scripts/gta-modded`: ProtonVPN on if it's off, GTA from Steam, then `~/.local/bin/modloader` once the Rockstar window shows up; the VPN stays on) and has mods and Vanilla buttons. The › on Home's Game Mode tile opens it.
- **Settings borrowed from OmaSettings** (MIT, copy in `~/GitDank/CloneWars/omasettings`): search finds single settings, a changed row shows ↺ to put it back, **Windows** (gaps, border, rounding, see-through, blur, shadows, animations: applied live with `hyprctl eval`, only changed ones written to `~/.config/hypr/dankshell.lua`, which `hyprland.lua` loads last), **Timeouts** (screensaver and lock via `scripts/idle-set`, then a shell restart).
- Empty widgets (weather that missed its fetch) get nudged at most every 10 minutes.
- **Camera** (`modules/pages/Camera.qml`, `services/Webcam.qml`, `scripts/camera`): the Anker PowerConf C200 webcam, found by name. Live picture while the page shows (it lets go when you leave), every control as a slider or switch, anti-flicker, saved looks in `~/.config/dankshell/camera.json` (the picked look goes back on at plug-in), Open big in mpv, Reset to defaults. This camera turns auto exposure back on only when it's replugged. Separate from the DSLR webcam plugin. `... call dankshell center camera`.
- **Monitor pills** (`components/MonitorPills.qml`, in the hover card): one pill per monitor laid out like the desk, the one the mouse is on big and lit, workspace dots inside (click one to go there). Hover a pill and the card grows down with a live picture of that monitor's window; drag a pill onto another pill to move that window to the workspace showing there.
- **Tray + Docker row** (`components/TrayRow.qml`, `services/Docker.qml`, `config/Docker.js`, `scripts/docker-open`): the hover card shows tray apps (click opens/focuses, right-click opens the app's menu right in the card) and running containers (click opens the container's page as its own window on the second workspace of the mouse's monitor: 4 main, 5 left, 6 TV; clicking again focuses it). Pages and icons per container in `config/Docker.js`.
- **Drop on a workspace**: dragging a window over a monitor pill spreads it into that monitor's workspaces (1 · 4 · 7 main, 2 · 5 · 8 left, 3 · 6 · 9 TV, from `config/Docker.js` SPACES); drop on the number you want. Works on the window's own monitor too.
- **Glance row** (`components/GlanceRow.qml`, `services/Glance.qml`): the icon row in the hover card. Settings › Glance row picks what shows and in what order: tray apps (new ones show up by themselves until you hide them) and any bar widget (Weather, ProtonVPN...; shows its live icon/text, click opens its dropdown). Running Docker containers sit at the end.
- **Lyrics** on the Pandora page (`services/Lyrics.qml`, `scripts/lyrics.sh` from DankBar): synced lyrics from lrclib.net, the line being sung lit in the middle; fold the card with its header.
