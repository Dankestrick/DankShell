pragma Singleton
import QtQuick
import Quickshell
import qs.Ui
import ".."
import "../config/Widgets.js" as Widgets
import "../config/Plugins.js" as Plugins
import "../config/WeatherIcons.js" as WeatherIcons

// WidgetHost — runs your Omarchy bar widgets (webcam, mail, Dropbox, network,
// DualSense, weather, updates, tray...) inside DankShell, the way the stock
// bar does: each widget gets Omarchy's own PluginBarApi as its `bar`, so it
// works exactly as it does on the stock bar, dropdown included.
//
// The one change: a dropdown asks the bar how far down to open
// (`barSizeFor`), and we answer "just under the island" for that monitor.
Singleton {
  id: host

  // Set by Bar.qml from what Omarchy hands the bar.
  property var registry: null
  property var shell: null

  // The widgets to show: their shell.json entries, in bar order.
  readonly property var entries: {
    const cfg = PluginHost.shellConfig || {}
    const layout = cfg.bar && cfg.bar.layout ? cfg.bar.layout : {}
    const out = [], seen = {}
    for (const sec of Widgets.SECTIONS) {
      for (const e of (Array.isArray(layout[sec]) ? layout[sec] : [])) {
        const id = typeof e === "string" ? e : (e && e.id ? String(e.id) : "")
        if (!id || seen[id] || Widgets.SKIP.indexOf(id) >= 0) continue
        seen[id] = true
        out.push(typeof e === "string" ? { id: id } : e)
      }
    }
    return out
  }
  // ── Every plugin, one list ────────────────────
  // Your plugins with a full page (config/Plugins.js) first, then every bar
  // widget. The Center window's Plugins tab lists all of them; the pinned
  // ones (Settings.v.pinned) also sit in the island's top row.
  //   kind "page":   opens its page (in the island when pinned, else Center)
  //   kind "widget": the real widget, with its own dropdown
  readonly property var catalog: {
    const out = Plugins.active().map(p => ({ key: p.key, name: p.name, icon: p.icon, sub: p.sub || "", kind: "page" }))
    for (const e of entries) {
      if (!componentFor(e.id) || Plugins.byId(e.id)) continue   // has its own page
      out.push({ key: e.id, name: nameFor(e.id), icon: Widgets.ICONS[e.id] || "extension",
                 sub: Widgets.ABOUT[e.id] || "", kind: "widget", entry: e })
    }
    return out
  }
  function item(key) { return catalog.find(c => c.key === key) || null }
  function nameFor(id) {
    if (Widgets.NAMES[id]) return Widgets.NAMES[id]
    const reg = registry
    const w = reg && reg.widgets ? reg.widgets[id] : null
    const n = w && w.metadata && w.metadata.displayName ? String(w.metadata.displayName) : ""
    return n || id.split(".").pop().replace(/[-_]/g, " ")
  }

  function componentFor(id) {
    const reg = registry
    if (!reg || !reg.widgets) return null
    void(reg.revision)
    return reg.widgets[id] ? reg.widgets[id].component : null
  }

  // ── How far down a dropdown opens, per monitor ──
  property var drops: ({})
  function setDrop(screenName, y) {
    if (drops[screenName] === y) return
    const next = Object.assign({}, drops); next[screenName] = y; drops = next
  }
  function dropFor(screenName) { return drops[screenName] || 44 }

  // ── One open dropdown at a time ───────────────
  property var active: null
  property string activeOwnerId: ""
  readonly property bool popoutOpen: active !== null
  function requestPopout(pluginId, owner) {
    if (active === owner) return
    const old = active
    active = owner
    activeOwnerId = pluginId
    if (old) {
      if (typeof old.closeForPopoutSwitch === "function") old.closeForPopoutSwitch()
      else if (typeof old.close === "function") old.close()
    }
  }
  function releasePopout(owner) { if (active === owner) { active = null; activeOwnerId = "" } }
  function closeAll() { const a = active; if (a && typeof a.close === "function") a.close(); active = null; activeOwnerId = "" }

  // ── Tooltip text (the dashboard shows it under its buttons) ──
  property string tip: ""

  // ── Live widgets, for broadcast() and click targets ──
  property var live: []
  property var targets: []     // [{ id, target }]
  function addLive(item) { live = live.concat([item]) }
  function removeLive(item) { live = live.filter(i => i !== item) }

  // Open a widget's dropdown the way Omarchy's own bar does: its open()
  // (every widget with a dropdown has one). Never a pretend click: on some
  // widgets a click is an action (the webcam's turns the camera on/off).
  function canOpen(widget) { return !!widget && typeof widget.open === "function" }
  function openWidget(widget) { if (!canOpen(widget)) return false; widget.open(); return true }

  // A widget that came up empty (weather that missed its first fetch while
  // the shell was starting) gets asked to try again: once soon after start,
  // and whenever the dashboard opens.
  property real lastNudge: 0
  function refreshEmpty() {
    // At most every 10 minutes, so a service that's refusing us isn't hammered.
    if (Date.now() - lastNudge < 600000) return
    lastNudge = Date.now()
    for (const w of live) {
      if (!w || typeof w.refresh !== "function") continue
      const b = findButton(w)
      if (b && "text" in b && String(b.text || "") === "") { try { w.refresh() } catch (e) { } }
    }
  }
  Timer { interval: 20000; running: true; onTriggered: host.refreshEmpty() }

  // Weather with a saved location gets its icon only from open-meteo; when
  // open-meteo refuses (403 on 2026-11-18) the icon stays blank and the
  // widget hides, even though its wttr.in reading came in fine. Fill the
  // icon from that reading with Omarchy's own icon table. open-meteo
  // overwrites it as soon as it answers again.
  function fillWeather() {
    for (const w of live) {
      if (!w || w.moduleName !== "omarchy.weather") continue
      for (const c of (w.data || [])) {
        let p = null
        try { p = c && c.item && "label" in c.item && "report" in c.item ? c.item : null } catch (e) { }
        if (!p || p.label !== "" || !p.report || !p.report.current_condition) continue
        const cc = p.report.current_condition[0]
        if (cc && cc.weatherCode !== undefined) p.label = WeatherIcons.iconForCode(cc.weatherCode, false)
      }
    }
  }
  Timer { interval: 30000; repeat: true; running: true; triggeredOnStart: true; onTriggered: host.fillWeather() }

  // A widget's own bar button (the first thing in it that can be pressed).
  function findButton(item) {
    const queue = [{ it: item, d: 0 }]
    while (queue.length) {
      const n = queue.shift()
      if (n.it && typeof n.it.triggerPress === "function") return n.it
      if (!n.it || n.d >= 6 || !n.it.children) continue
      for (let i = 0; i < n.it.children.length; i++) queue.push({ it: n.it.children[i], d: n.d + 1 })
    }
    return null
  }

  // The card of a widget's open dropdown (Omarchy's KeyboardPanel or
  // PopupCard), so a page can place it. Same search DankBar used.
  function cardOf(widget) {
    const queue = [widget], seen = []
    let panel = null
    while (queue.length && seen.length < 80) {
      const c = queue.shift()
      if (!c || seen.indexOf(c) >= 0) continue
      seen.push(c)
      try { if ("anchorItem" in c && "cardOrigin" in c && "contentWidth" in c && "open" in c) { panel = c; break } } catch (e) { }
      if (c.children) for (let i = 0; i < c.children.length; i++) queue.push(c.children[i])
      if (c.data) for (let j = 0; j < c.data.length; j++) queue.push(c.data[j])
      try { if (c.item && typeof c.item === "object") queue.push(c.item) } catch (e) { }
    }
    if (!panel) return null
    let objs = []
    if (panel.contentItem && panel.contentItem.children) objs = objs.concat(Array.from(panel.contentItem.children))
    if (panel.data) objs = objs.concat(Array.from(panel.data))
    for (const o of objs) { try { if (o && "contentTopInset" in o && "radius" in o && "color" in o) return o } catch (e) { } }
    return null
  }

  // One api per widget id, shared by every monitor (as the stock bar does).
  property var apis: ({})
  function apiFor(id) {
    if (apis[id]) return apis[id]
    const entryShell = shell && typeof shell.pluginShellForBarEntry === "function"
      ? shell.pluginShellForBarEntry("io.github.dankestrick.dankshell", id) : null
    const api = apiComponent.createObject(host, {
      pluginId: id, moduleName: id, shell: entryShell,
      _showTooltip: function(target, text) { host.tip = text },
      _hideTooltip: function(target) { host.tip = "" },
      _registerClickTarget: function(t) { host.targets = host.targets.concat([{ id: id, target: t }]) },
      _unregisterClickTarget: function(t) { host.targets = host.targets.filter(x => x.target !== t) },
      _requestPopout: function(owner) { host.requestPopout(id, owner) },
      _releasePopout: function(owner) { host.releasePopout(owner) },
      _switchPanelFrom: function(owner, direction) { return false },
      _notePopoutCard: function(card) { },
      _popoutCardFor: function(owner) { return null },
      _targetBelongsToWindow: function(target, window) {
        try { return !!target && target.QsWindow.window === window } catch (e) { return false }
      },
      _moduleWidgets: function(requested) {
        return String(requested) === id ? host.live.filter(w => w.moduleName === id) : []
      },
      _run: function(command) { if (command) Quickshell.execDetached(["bash", "-c", String(command)]) },
      _setCenterHoverRevealSuppressed: function(v) { }
    })
    const next = Object.assign({}, apis); next[id] = api; apis = next
    return api
  }

  Component { id: apiComponent; DankBarApi { } }
}
