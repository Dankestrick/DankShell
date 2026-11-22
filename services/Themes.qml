pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Themes — your Omarchy themes for the theme switcher: name, colors and the
// wallpaper Omarchy remembers for each one. Applying runs `omarchy theme set`,
// the same as Omarchy's own menu, so everything else follows along.
Singleton {
  id: themes

  property var list: []          // [{ slug, name, colors, wallpaper }]
  property string current: ""    // slug of the theme in use
  property bool loading: false
  property string applying: ""   // slug being applied right now

  Component.onCompleted: reload()   // ready before the Themes window asks

  readonly property string scriptPath: Qt.resolvedUrl("../scripts/themes.py").toString().replace("file://", "")

  function reload() {
    if (loader.running) return
    loading = true
    loader.running = true
  }

  // Apply a theme; thenWallpaper (a path) goes up right after it.
  property string thenWallpaper: ""
  function apply(slug, wall) {
    if (!slug || applying !== "") return
    applying = slug
    thenWallpaper = wall || ""
    setter.command = ["omarchy", "theme", "set", slug]
    setter.running = true
  }

  // A theme's color by name, with sensible fallbacks for older themes.
  function color(t, key) {
    const c = t && t.colors ? t.colors : {}
    if (c[key]) return c[key]
    if (key === "accent") return c.blue || c.cyan || c.foreground || "#888888"
    if (key === "background") return "#111111"
    if (key === "foreground") return "#dddddd"
    return c.foreground || "#888888"
  }

  Process {
    id: loader
    command: ["python3", "-I", themes.scriptPath]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const d = JSON.parse(text)
          themes.current = d.current || ""   // before the list, so the switcher can find it
          themes.list = d.themes || []
        } catch (e) { console.warn("dankshell: theme list unreadable:", e) }
        themes.loading = false
      }
    }
    onExited: themes.loading = false
  }

  Process {
    id: setter
    onExited: {
      themes.applying = ""
      if (themes.thenWallpaper !== "") { Wallpapers.apply(themes.thenWallpaper); themes.thenWallpaper = "" }
      themes.reload(); Wallpapers.reload()
    }
  }
}
