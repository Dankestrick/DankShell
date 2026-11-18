# DankShell

A dynamic island shell for Omarchy. One pill at the top of each screen that grows when you hover it and opens a dashboard when you click it.

## Where things live

| Folder | What's in it | Open it when you want to... |
|---|---|---|
| `config/` | `Sizes.qml`, `Motion.qml`, `Theme.qml` | change a size, a speed, a color, a font |
| `services/` | where data comes from (time, music, workspaces...) | change what the island knows |
| `components/` | small pieces used everywhere (`Pill`, `Icon`) | change how a basic piece looks |
| `modules/island/` | the island and its states (`Closed`, later `Hover`, `Dashboard`) | change what the island shows |
| `modules/pages/` | one file per dashboard page | change one page |
| `modules/settings/` | one file per settings section | change a settings screen |

`Bar.qml` is only the doorway Omarchy opens. `qmldir` lists every piece so any file can use any other.

## Try it

```sh
rsync -a --delete --exclude .git ~/GitDank/DankShell/ ~/.config/omarchy/plugins/io.github.dankestrick.dankshell/
```

Turn it on: set `"bar": { "id": "io.github.dankestrick.dankshell" }` in `~/.config/omarchy/shell.json`.
Back to the stock bar: set it to `"omarchy.bar"`.

## Credits

Design numbers from saneAspect's videos. Island ideas from ZenoShell (MIT).
