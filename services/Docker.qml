pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../config/Docker.js" as DockerConfig

// Docker — the containers that are running, for the hover card. Each one gets
// an icon; clicking opens its web page as its own window on the second
// workspace of the monitor the mouse is on (4 main, 5 left, 6 TV), or focuses
// that window if it's already open (scripts/docker-open).
Singleton {
  id: dk

  property bool watching: false       // the hover card is showing
  property var running: []            // [{ name, image, url, icon }]

  function refresh() { if (!ps.running) ps.running = true }
  Process {
    id: ps
    command: ["docker", "ps", "--format", "{{.Names}}\t{{.Image}}\t{{.Ports}}"]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = []
        for (const line of text.split("\n")) {
          if (!line.trim()) continue
          const [name, image, ports] = line.split("\t")
          let url = DockerConfig.URLS[name] || ""
          if (!url) {
            const m = String(ports || "").match(/:(\d+)->\d+\/tcp/)
            if (m) url = "http://localhost:" + m[1]
          }
          out.push({ name: name, image: image, url: url, icon: DockerConfig.ICONS[name] || "deployed_code" })
        }
        dk.running = out
      }
    }
  }
  Timer { interval: 4000; repeat: true; running: dk.watching; triggeredOnStart: true; onTriggered: dk.refresh() }
  Component.onCompleted: refresh()

  readonly property string helper: Qt.resolvedUrl("../scripts/docker-open").toString().replace("file://", "")
  // Second workspace of the mouse's monitor from Settings.v.monitorSpaces;
  // a monitor not listed there opens it on the workspace it's showing.
  function targetWorkspace() {
    const m = Hyprland.focusedMonitor
    const spaces = m ? (Settings.v.monitorSpaces || {})[m.name] : null
    if (Array.isArray(spaces) && spaces.length > 1) return spaces[1]
    return m && m.activeWorkspace ? m.activeWorkspace.id : 1
  }
  function open(c) {
    if (!c.url) return
    Quickshell.execDetached([helper, c.name, c.url, String(targetWorkspace())])
  }
}
