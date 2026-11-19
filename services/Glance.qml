pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// Glance — what sits in the Glance row (the icon row in the hover card), in
// your order. Two kinds of things:
//   tray apps ("tray:<id>"): Vesktop, Steam, Dropbox... A new tray app shows
//     up at the end by itself until you hide it.
//   bar widgets (their id, e.g. "omarchy.weather"): only when you add them.
//   pages (their key, e.g. "audio"): your page plugins; click opens the page.
// Settings › Glance row reorders, hides and adds. Running Docker containers
// always sit at the end (TrayRow).
Singleton {
  id: g

  readonly property var trayItems: SystemTray.items.values
  function trayKey(t) { return "tray:" + t.id }
  function trayName(t) { return t.tooltipTitle || t.title || t.id }

  // Everything showing, in order: [{ key, kind, name, icon, tray, entry }]
  readonly property var shown: {
    const order = Settings.v.glance || []
    const hidden = Settings.v.glanceHidden || []
    const out = [], seen = {}
    for (const k of order) {
      if (k.startsWith("tray:")) {
        const t = trayItems.find(x => trayKey(x) === k)
        if (t && hidden.indexOf(t.id) < 0) { out.push({ key: k, kind: "tray", name: trayName(t), icon: "apps", tray: t }); seen[k] = true }
      } else {
        const c = WidgetHost.item(k)
        if (c && c.kind === "widget") { out.push({ key: k, kind: "widget", name: c.name, icon: c.icon, entry: c.entry }); seen[k] = true }
        else if (c && c.kind === "page") { out.push({ key: k, kind: "page", name: c.name, icon: c.icon }); seen[k] = true }
      }
    }
    for (const t of trayItems) {
      const k = trayKey(t)
      if (!seen[k] && hidden.indexOf(t.id) < 0) out.push({ key: k, kind: "tray", name: trayName(t), icon: "apps", tray: t })
    }
    return out
  }
  // What you could add: hidden tray apps and bar widgets not showing.
  readonly property var available: {
    const hidden = Settings.v.glanceHidden || []
    const keys = shown.map(s => s.key)
    const out = []
    for (const t of trayItems)
      if (hidden.indexOf(t.id) >= 0) out.push({ key: trayKey(t), kind: "tray", name: trayName(t), icon: "apps", tray: t })
    for (const c of WidgetHost.catalog)
      if (keys.indexOf(c.key) < 0) out.push({ key: c.key, kind: c.kind, name: c.name, icon: c.icon, entry: c.entry })
    return out
  }

  function has(key) { return shown.some(s => s.key === key) }
  function add(key) {
    if (key.startsWith("tray:"))
      Settings.set("glanceHidden", (Settings.v.glanceHidden || []).filter(id => "tray:" + id !== key))
    const order = shown.map(s => s.key).filter(k => k !== key)
    order.push(key)
    Settings.set("glance", order)
  }
  function remove(key) {
    if (key.startsWith("tray:")) {
      const id = key.slice(5)
      const h = (Settings.v.glanceHidden || []).filter(x => x !== id); h.push(id)
      Settings.set("glanceHidden", h)
    }
    Settings.set("glance", shown.map(s => s.key).filter(k => k !== key))
  }
  // Move one spot (-1 = left, 1 = right).
  function move(key, d) {
    const order = shown.map(s => s.key)
    const i = order.indexOf(key), j = i + d
    if (i < 0 || j < 0 || j >= order.length) return
    order[i] = order[j]; order[j] = key
    Settings.set("glance", order)
  }

  // The live widget's button, to mirror its icon/text (weather shows its temp).
  function buttonFor(key) {
    const w = WidgetHost.live.find(x => x.moduleName === key)
    return w ? WidgetHost.findButton(w) : null
  }
}
