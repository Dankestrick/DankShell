pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wallpapers — pictures for the wallpaper switcher: the theme in use first,
// then every other theme's and DankWallpapers. Applying runs
// `omarchy theme bg set`, the same as Omarchy's own background menu.
Singleton {
  id: walls

  property var items: []          // [{ path, name, mine }]
  property string current: ""     // path of the wallpaper on screen
  property string applying: ""

  readonly property string scriptPath: Qt.resolvedUrl("../scripts/wallpapers.py").toString().replace("file://", "")

  function reload() { if (!loader.running) loader.running = true }
  function apply(path) {
    if (!path || applying !== "") return
    applying = path
    current = path
    setter.command = ["omarchy", "theme", "bg", "set", path]
    setter.running = true
  }

  Process {
    id: loader
    command: ["python3", "-I", walls.scriptPath]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const d = JSON.parse(text)
          walls.current = d.current || ""
          walls.items = d.items || []
        } catch (e) { console.warn("dankshell: wallpaper list unreadable:", e) }
      }
    }
  }
  Process { id: setter; onExited: walls.applying = "" }
}
