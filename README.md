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
- **Keys** (in `~/.config/hypr/bindings.lua`, the "dankshell" block): Super+Alt+A dashboard, Super+N notifications, Super+U plugins, Super+Alt+I settings, Super+Alt+Y games. Same key again closes.
- **Plugins window extras**: "All plugins" grid with live status (`services/Status.qml`), status in the sidebar, a Background group for service-only plugins, dropdowns get the whole right side.
- **Games** (`modules/pages/Game.qml`, `scripts/games.py`): Game Mode, DualSense status, your Steam games (most recent first), Play launches through Steam and can turn Game Mode on. The › on Home's Game Mode tile opens it.
