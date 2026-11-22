pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config/Plugins.js" as Plugins

// Installed — every Omarchy plugin you have, for the Plugins window:
// Running (yours, turned on), Not running (yours, turned off), Background
// (yours, on, but nothing to click: services like Grok Usage), then Omarchy's
// own built-ins. Read with scripts/plugins.py (`omarchy plugin list` plus
// each manifest). Bars (DankShell, Omacale, the stock bar) aren't listed.
Singleton {
  id: inst

  property var all: []
  readonly property string scriptPath: Qt.resolvedUrl("../scripts/plugins.py").toString().replace("file://", "")

  // Center window entries, in order: Running, Not running, Omarchy.
  readonly property var items: {
    const rows = all.filter(p => p.kinds.indexOf("bar") < 0).map(p => {
      const page = Plugins.byId(p.id)
      const it = WidgetHost.item(p.id)
      const hasWidget = !!WidgetHost.componentFor(p.id) || (!!it && it.kind === "widget")
      const opens = p.kinds.some(k => k === "overlay" || k === "panel" || k === "menu")
      return {
        key: page ? page.key : p.id, id: p.id, name: page ? page.name : p.name,
        icon: page ? page.icon : (WidgetHost.item(p.id) ? WidgetHost.item(p.id).icon : iconFor(p)),
        sub: page && page.sub ? page.sub : p.description,
        description: p.description, version: p.version, kinds: p.kinds, enabled: p.enabled, firstParty: p.firstParty,
        group: p.firstParty ? "Omarchy" : !(p.enabled || page) ? "Not running"
             : (!page && !hasWidget && !opens) ? "Background" : "Running",
        // how you use it in the window
        use: page ? "page" : (p.enabled && hasWidget) ? "widget" : (p.enabled && opens) ? "open" : "info"
      }
    })
    const rank = { "Running": 0, "Not running": 1, "Background": 2, "Omarchy": 3 }
    return rows.sort((a, b) => rank[a.group] - rank[b.group] || (a.enabled === b.enabled ? 0 : a.enabled ? -1 : 1) || a.name.localeCompare(b.name))
  }

  function iconFor(p) {
    const k = p.kinds
    if (k.indexOf("overlay") >= 0) return "open_in_new"
    if (k.indexOf("panel") >= 0) return "web_asset"
    if (k.indexOf("bar-widget") >= 0) return "widgets"
    return "settings_suggest"
  }

  function reload() { if (!proc.running) proc.running = true }
  function setEnabled(id, on) {
    Quickshell.execDetached(["omarchy", "plugin", on ? "enable" : "disable", id])
    reloadLater.restart()
  }
  Timer { id: reloadLater; interval: 2500; onTriggered: inst.reload() }
  property int retries: 0
  Timer { id: retry; interval: 2000; onTriggered: inst.reload() }
  onAllChanged: retries = 0

  Process {
    id: proc
    command: ["python3", "-I", inst.scriptPath]
    stdout: StdioCollector {
      onStreamFinished: {
        let list = null
        try { list = JSON.parse(text) } catch (e) { console.warn("dankshell: plugin list unreadable:", e) }
        // An empty list means Omarchy was busy (mid install/remove): keep the old one, ask again.
        if (list && list.length) inst.all = list
        else if (inst.retries++ < 5) retry.restart()
      }
    }
  }
  Component.onCompleted: reload()
}
