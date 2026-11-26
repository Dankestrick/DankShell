pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Hypr — the window look settings (gaps, borders, rounding, blur...).
// Borrowed from OmaSettings' way of doing it (MIT, copy in
// OmaSettings, MIT): a change is applied live with
// `hyprctl eval`, and only the settings you changed are written to
// ~/.config/hypr/dankshell.lua, which hyprland.lua loads last. Your own
// config files are never rewritten. Undo drops the override and reloads.
Singleton {
  id: h

  readonly property string file: Quickshell.env("HOME") + "/.config/hypr/dankshell.lua"
  property var current: ({})   // what Hyprland says now, by key

  function value(key) { return key in Settings.v.hypr ? Settings.v.hypr[key] : current[key] }
  function changed(key) { return key in Settings.v.hypr }

  function set(key, v) {
    const next = Object.assign({}, Settings.v.hypr); next[key] = v
    Settings.set("hypr", next)
    Quickshell.execDetached(["hyprctl", "eval", "hl.config(" + table([[key, v]]) + ")"])
    writeFile()
  }
  function reset(key) {
    const next = Object.assign({}, Settings.v.hypr); delete next[key]
    Settings.set("hypr", next)
    writeFile(true)
  }

  // [["general:gaps_in", 10], ...] -> "{ general = { gaps_in = 10 } }"
  function table(pairs) {
    const root = {}
    for (const [key, v] of pairs) {
      const parts = key.split(":"); let o = root
      for (let i = 0; i < parts.length - 1; i++) o = o[parts[i]] = o[parts[i]] || {}
      o[parts[parts.length - 1]] = v
    }
    const lua = (o, ind) => typeof o === "object"
      ? "{\n" + Object.keys(o).map(k => ind + "  " + k + " = " + lua(o[k], ind + "  ")).join(",\n") + ",\n" + ind + "}"
      : typeof o === "boolean" ? String(o) : String(Math.round(o * 1000) / 1000)
    return lua(root, "")
  }

  property bool reloadAfterWrite: false
  function writeFile(reload) {
    reloadAfterWrite = !!reload
    const pairs = Object.keys(Settings.v.hypr).sort().map(k => [k, Settings.v.hypr[k]])
    luaFile.setText("-- Written by DankShell (Settings › Windows). Loaded last from hyprland.lua.\n"
      + "-- Only the settings you changed are here. Change them in DankShell; edits here get overwritten.\n"
      + (pairs.length ? "hl.config(" + table(pairs) + ")\n" : ""))
  }
  FileView {
    id: luaFile
    path: h.file
    printErrors: false
    onSaved: if (h.reloadAfterWrite) { h.reloadAfterWrite = false; Quickshell.execDetached(["hyprctl", "reload"]); reread.restart() }
  }
  Timer { id: reread; interval: 700; onTriggered: h.reload() }

  // Read Hyprland's current values for every key in the Windows section.
  property var keys: []
  function reload() {
    if (!keys.length || reader.running) return
    reader.command = ["bash", "-c", keys.map(k => "hyprctl -j getoption " + k).join("; ")]
    reader.running = true
  }
  Process {
    id: reader
    stdout: StdioCollector {
      onStreamFinished: {
        const out = {}
        for (const chunk of text.split(/\n(?=\{)/)) {
          try {
            const d = JSON.parse(chunk)
            out[d.option] = "int" in d ? d.int : "float" in d ? d.float : "bool" in d ? d.bool
                          : "css" in d ? Number(String(d.css).split(" ")[0]) : undefined
          } catch (e) { }
        }
        h.current = out
      }
    }
  }
}
