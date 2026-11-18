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

- **Center window** (`modules/center/`): plugin pages, Sound & Bluetooth and Settings pop up in the middle of the screen. Open from the dashboard's bottom buttons or the gear, or `qs ipc -p /usr/share/omarchy/shell call dankshell center <page>`.
- **Settings** (`modules/settings/`, `config/SettingsList.js`, `services/Settings.qml`): sliders that reshape the island live; saved in `~/.config/dankshell/settings.json`.
- **Wallpapers** (`modules/island/WallpaperSwitcher.qml`): the island turns into a carousel. `... call dankshell walls`.
- **Game mode** (`scripts/gamemode on|off|toggle|status`): stay awake, notifications silenced, animations off, night light off, performance power profile; off puts each back. Tile on Home, or `... call dankshell gamemode`.
