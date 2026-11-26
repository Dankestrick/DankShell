# DankShell

A dynamic island shell for [Omarchy](https://omarchy.org). One pill at the top of each screen that grows when you hover it and opens a dashboard when you click it. Every menu (plugins, settings, audio, themes, games, notifications, power) opens in one centered window with sidebar tabs.

It's a bar plugin (`kinds: ["bar"]`) for Omarchy's shell, so it replaces the stock bar while it's on and hands it back when it's off.

## Install

You need Omarchy with the Quickshell shell (Omarchy 4.x) and `jq`.

```sh
git clone https://github.com/Dankestrick/DankShell.git ~/DankShell
~/DankShell/scripts/dankshell install   # copies it into ~/.config/omarchy/plugins/
~/DankShell/scripts/dankshell on        # makes it your bar (restarts the shell)
```

Back to the stock bar any time:

```sh
~/DankShell/scripts/dankshell off
```

`on` and `off` only change `bar.id` and `disabledPlugins` in `~/.config/omarchy/shell.json`, and `on` remembers what was there before so `off` puts it back. `scripts/dankshell status` shows which bar is on.

To update: `git pull` in the clone, then `scripts/dankshell install` and `omarchy restart shell`.

### Optional extras

These are only needed for the part that uses them:

| For | Install |
|---|---|
| Camera page | `v4l2-utils` (and `mpv` for Open big) |
| Games window | Steam (plus any other launcher you use) |
| Docker row in the hover card | Docker |
| VPN tile | the ProtonVPN app, or any VPN/WireGuard connection saved in NetworkManager (the tile hides when there's none) |

### Keys (optional)

Add these to `~/.config/hypr/bindings.lua`. The same key again closes the window.

```lua
o.bind("SUPER + ALT + A", "DankShell dashboard", "omarchy-shell dankshell toggle")
o.bind("SUPER + N", "DankShell notifications", "omarchy-shell dankshell center notifications")
o.bind("SUPER + U", "DankShell plugins", "omarchy-shell dankshell plugins")
o.bind("SUPER + ALT + I", "DankShell settings", "omarchy-shell dankshell settings")
o.bind("SUPER + ALT + Y", "DankShell games", "omarchy-shell dankshell center game")
```

### Window settings (optional)

Settings › Windows changes gaps, borders, rounding, blur and the rest live. To keep them after a reboot, add this as the last line of `~/.config/hypr/hyprland.lua`:

```lua
require("hypr.dankshell")
```

## Your settings

Everything you change in DankShell is saved under `~/.config/dankshell/`. A few files you can write by hand:

| File | What it does |
|---|---|
| `wallpapers.json` | extra wallpaper folders for the Themes window: `{"folders": ["~/Pictures/Wallpapers"]}` |
| `git-installs.json` | git checkouts the Updates tab keeps an eye on: `{"roots": ["~/src"], "add": ["~/ComfyUI"], "skip": ["name"], "ownOwners": ["your-github-name"]}` |
| `settings.json` → `monitorSpaces` | workspace slots per monitor for dragging a window onto a pill: `"monitorSpaces": {"DP-1": [1, 4, 7], "HDMI-A-1": [2, 5, 8]}`. Without it each pill shows the workspaces that monitor has open |
| `launchers.json` | your own launch script for a Steam game, by app id: `{"271590": {"name": "Modded", "script": "~/bin/my-launch"}}` |

Set `DANKSHELL_CAMERA` to a camera's name (as `v4l2-ctl --list-devices` prints it) to pick one when you have several.

## Plugin pages

`config/Plugins.js` lists plugins that get a full page in the dashboard (OmaPandora, OmaKraken, OmaGravastar, OmaiPhone, OmaJournal, DualSense, Omarchy's Audio). A page only shows when its plugin is installed. Every other plugin you have still shows up in the Plugins window with its own icon and dropdown, and you can pin any of them to the island's top row.

## Where things live

| Folder | What's in it | Open it when you want to... |
|---|---|---|
| `config/` | `Sizes.qml`, `Motion.qml`, `Theme.qml`, `Plugins.js`, `Docker.js` | change a size, a speed, a color, a font |
| `services/` | where data comes from (time, music, workspaces...) | change what the island knows |
| `components/` | small pieces used everywhere (`Pill`, `Icon`) | change how a basic piece looks |
| `modules/island/` | the island and its states (`Hover`, `Dashboard`; the clock lives in `Island.qml`) | change what the island shows |
| `modules/center/` | the centered window and its tabs | change a window |
| `modules/pages/` | one file per page | change one page |
| `modules/settings/` | one file per settings section | change a settings screen |
| `scripts/` | small helpers the pages call | change what a button does |

`Bar.qml` is only the doorway Omarchy opens. `qmldir` lists every piece so any file can use any other.

IPC for scripts and testing: `qs ipc -p /usr/share/omarchy/shell call dankshell open|close|toggle|plugins|settings|center <page>`.

## What's in it

- **Center window** (`modules/center/`): opens as **Plugins** (puzzle button; every installed plugin: Running, Not running, Omarchy; use each right there: its page, its real dropdown placed in the window, Open for its own window, Turn on when off; `services/Installed.qml` + `scripts/plugins.py`), **Settings** (gear), or **Notifications / Sound**. `qs ipc -p /usr/share/omarchy/shell call dankshell plugins|settings|center <page>`.
- **Settings** (`modules/settings/`, `config/SettingsList.js`, `services/Settings.qml`): sliders that reshape the island live; saved in `~/.config/dankshell/settings.json`.
- **Wallpapers** (`modules/island/WallpaperSwitcher.qml`): the island turns into a carousel. `... call dankshell walls`.
- **Plugins tab + top row**: every plugin (your page plugins and every bar widget, via `services/WidgetHost.qml` + `config/Widgets.js`) is listed in the Center window's Plugins tab. Pin any of them (Pin button on its page, or Settings › Top row, where arrows set the order) and it joins the island's top row next to themes/wallpapers/settings: page plugins open inside the island like tabs, widgets show their real icon and dropdown. `omarchy-shell shell summon <id>` opens one. `... call dankshell widgets` lists what started.
- **Date** under the dashboard clock opens the Journal.
- **Game mode** (`scripts/gamemode on|off|toggle|status`): stay awake, notifications silenced, animations off, night light off, performance power profile; off puts each back. Tile on Home, or `... call dankshell gamemode`.
- **Device button** in the dashboard top row (between wallpapers and plugins) opens the Device window on the last page you used there (Games, Camera, System, Sound, Notifications). **Right-click** anywhere in the Center window goes back to the dashboard (or just closes it when a key opened it).
- **Keys** (in `~/.config/hypr/bindings.lua`, the "dankshell" block): Super+Alt+A dashboard, Super+N notifications, Super+U plugins, Super+Alt+I settings, Super+Alt+Y games. Same key again closes.
- **Plugins window extras**: "All plugins" grid with live status (`services/Status.qml`), status in the sidebar, a Background group for service-only plugins, dropdowns get the whole right side.
- **Games** (`modules/pages/Game.qml`, `scripts/games.py`): Game Mode, DualSense status, your Steam games (most recent first), Play launches through Steam and can turn Game Mode on. Games with an r2modman profile (Valheim) play modded with the same launch r2modman's "Start modded" sends; their card has Modded, Vanilla and Mods (opens r2modman) buttons. Every card has the same launch buttons; the lit one is what the big Play does, right-click a button to make it the default (Settings.v.gameDefaults). Give any game your own launch script in `~/.config/dankshell/launchers.json` and its card gets a button for it. The › on Home's Game Mode tile opens it.
- **Settings borrowed from OmaSettings** (MIT): search finds single settings, a changed row shows ↺ to put it back, **Windows** (gaps, border, rounding, see-through, blur, shadows, animations: applied live with `hyprctl eval`, only changed ones written to `~/.config/hypr/dankshell.lua`, which `hyprland.lua` loads last), **Timeouts** (screensaver and lock via `scripts/idle-set`, then a shell restart).
- Empty widgets (weather that missed its fetch) get nudged at most every 10 minutes.
- **Camera** (`modules/pages/Camera.qml`, `services/Webcam.qml`, `scripts/camera`): your webcam: the first real camera it finds (virtual v4l2loopback cameras are skipped), or the one named in `$DANKSHELL_CAMERA`. Live picture while the page shows (it lets go when you leave), every control as a slider or switch, anti-flicker, saved looks in `~/.config/dankshell/camera.json` (the picked look goes back on at plug-in), Open big in mpv, Reset to defaults. Separate from the DSLR webcam plugin. `... call dankshell center camera`.
- **Monitor pills** (`components/MonitorPills.qml`, in the hover card): one pill per monitor laid out like the desk, the one the mouse is on big and lit, workspace dots inside (click one to go there). Hover a pill and the card grows down with a live picture of that monitor's window; drag a pill onto another pill to move that window to the workspace showing there.
- **Tray + Docker row** (`components/TrayRow.qml`, `services/Docker.qml`, `config/Docker.js`, `scripts/docker-open`): the hover card shows tray apps (click opens/focuses, right-click opens the app's menu right in the card) and running containers (click opens the container's page as its own window on the second workspace in that monitor's `monitorSpaces` list, or on the workspace it's showing; clicking again focuses it). Pages and icons per container in `config/Docker.js`.
- **Drop on a workspace**: dragging a window over a monitor pill spreads it into that monitor's workspaces (the ones it has open, or your own list in `monitorSpaces`, see Your settings); drop on the number you want. Works on the window's own monitor too.
- **Glance row** (`components/GlanceRow.qml`, `services/Glance.qml`): the icon row in the hover card. Settings › Glance row picks what shows and in what order: tray apps (new ones show up by themselves until you hide them) and any bar widget (Weather, ProtonVPN...; shows its live icon/text, click opens its dropdown). Running Docker containers sit at the end. Adding a widget that already sits in the other row (Glance or Top) asks first: Move it here, Keep both, or Cancel (`components/AskDouble.qml`).
- **Lyrics** on the Pandora page (`services/Lyrics.qml`, `scripts/lyrics.sh` from DankBar): synced lyrics from lrclib.net, the line being sung lit in the middle; fold the card with its header.
- **Plugin manager** (`modules/center/GetPlugins.qml`, `services/PluginManager.qml`, `scripts/plugin-manage`): the Plugins window's **Get plugins** page shows updates waiting for your git-installed plugins and the Omarchy marketplace (plugins.omarchy.org catalog, verified + most stars first; the window's search box searches it) with Install buttons. Every plugin's page has **Update** (when one is waiting) and **Remove** (asks first) in its header. Jobs run `omarchy plugin add|update|remove` detached and report through `~/.cache/dankshell/plugin-job.json`. Replaces Omaplug.
- **Audio** (`modules/pages/Audio.qml`, `services/Sound.qml`): Omarchy's audio panel rebuilt in DankShell's look: everything on/off (with Omarchy's volume names, "Concert hall"), output volume + devices, input volume + live mic level + devices, per-app volumes. Device window › Audio, and in the Plugins window as Omarchy's Audio; pinnable to the Top row, addable to the Glance row (pages can sit in the Glance row now). Bluetooth got its own Device page. Page Up / Page Down scroll any Center window page.
- **EQ** (`services/Eq.qml`, `scripts/eq`): a global equalizer on PipeWire's own filter-chain (no packages). Everything plays into "DankShell EQ", which plays into your real output and follows you when you switch outputs (from here, keys, or Omarchy's panel). Two layers: a headphone fix from AutoEq (8,850 headphones, searchable, remembered per output) and your 10 bands (±15 dB, presets Flat / Hearing boost / Footsteps / Bass boost / Vocal, save your own). Biggest boost comes off the top so nothing clips. Off by default; settings in `~/.config/dankshell/eq.json`; comes back on after a reboot if you left it on.
- **Dropdowns look like DankShell**: a plugin's dropdown shown in the Plugins window gets DankShell's card (raised gray, DankShell's corner, no bordered box), like the island already does for pinned ones. The colors of the controls inside (Omarchy's green "on"/"selected") are Omarchy's own styling for the whole desktop; native pages (like Audio) are the way to restyle those fully.
- **Keys** (Settings › Keys, `modules/settings/Keys.qml`): every keyboard shortcut you have (from `omarchy menu keybindings --print`) as key caps; the window's search box finds one by key or by what it does.

## Credits

Design numbers from saneAspect's videos. Island ideas from ZenoShell (MIT). Settings search and the Windows/Timeouts sections borrowed from OmaSettings (MIT). CPU/GPU readers in `scripts/monitor` by DanSmith888 (MIT). Weather icon table from Omarchy (MIT). Synced lyrics from [lrclib.net](https://lrclib.net). Headphone fixes from [AutoEq](https://github.com/jaakkopasanen/AutoEq).

## License

MIT, see [LICENSE](LICENSE).
