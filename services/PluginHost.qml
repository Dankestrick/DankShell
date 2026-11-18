pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config/Plugins.js" as Plugins

// PluginHost — runs your plugins' own services (and their windows, like
// Pandora's full player) inside DankShell, so their pages can use them.
//
// Why: Omarchy keeps a custom bar away from other plugins' services. So
// `scripts/dankshell on` puts each plugin on shell.json's disabledPlugins
// (Omarchy's copy stops, its settings stay), and this file runs the one copy.
// A plugin only runs here while it's on that list, so two copies never run
// at once. Ported from DankBar's DankHost.
Singleton {
  id: host

  readonly property string pluginsDir: Quickshell.env("HOME") + "/.config/omarchy/plugins"
  readonly property string shellJsonPath: Quickshell.env("HOME") + "/.config/omarchy/shell.json"

  property var shellConfig: ({})
  readonly property var disabled: Array.isArray(shellConfig.disabledPlugins) ? shellConfig.disabledPlugins : []

  // Running plugins, by key.
  property var live: ({})
  function hosted(key) { return live[key] || null }
  function service(key) { const h = live[key]; return h ? h.service : null }

  // The settings Omarchy kept for a plugin (its bar entry or plugins[] record).
  function entrySettings(id) {
    const c = shellConfig || {}
    const layout = c.bar && c.bar.layout ? c.bar.layout : {}
    for (const sec in layout) {
      const list = Array.isArray(layout[sec]) ? layout[sec] : []
      for (const e of list) if (e && typeof e === "object" && e.id === id) return e
    }
    for (const e of (Array.isArray(c.plugins) ? c.plugins : []))
      if (e && typeof e === "object" && e.id === id) return e
    return {}
  }

  FileView {
    path: host.shellJsonPath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try { host.shellConfig = JSON.parse(text()) || {} } catch (e) { console.warn("dankshell: shell.json unreadable:", e) }
    }
  }

  // Settings changed in shell.json reach the running services.
  onShellConfigChanged: {
    for (const k in live) {
      const h = live[k]
      if (h.service && typeof h.service.applySettings === "function") h.service.applySettings(entrySettings(h.pluginId))
      else if (h.service && "settings" in h.service) h.service.settings = entrySettings(h.pluginId)
    }
  }

  // One runner per plugin.
  Instantiator {
    model: Plugins.active()
    delegate: QtObject {
      id: h
      required property var modelData
      readonly property string pluginId: modelData.id
      readonly property string key: modelData.key
      readonly property string dir: host.pluginsDir + "/" + pluginId
      property var manifest: null
      property var service: null
      property var panel: null
      property bool started: false
      readonly property var settings: host.entrySettings(pluginId)
      readonly property bool panelOpen: !!(panel && panel.opened === true)
      readonly property bool wanted: !!manifest && host.disabled.indexOf(pluginId) >= 0
      onWantedChanged: sync()

      // What the plugin's own files get as `shell`: its service, and its
      // panel opened and closed here. Nothing else of the shell.
      readonly property QtObject shim: QtObject {
        function serviceFor(id) { return String(id || "") === h.pluginId ? h.service : null }
        function summon(id, payloadJson) { return h.openPanel(id, payloadJson) }
        function hide(id) { return h.closePanel(id) }
        function toggle(id, payloadJson) { return h.panelOpen ? h.closePanel(id) : h.openPanel(id, payloadJson) }
        function isPluginOpen(id) { return String(id || "") === h.pluginId && h.panelOpen }
      }

      function entryUrl(kind) {
        const ep = manifest && manifest.entryPoints ? manifest.entryPoints[kind] : ""
        if (!ep || String(ep).indexOf("..") >= 0) return ""
        return "file://" + dir + "/" + ep
      }
      function make(kind, props) { return makeUrl(entryUrl(kind), kind, props) }
      function makeUrl(url, kind, props) {
        if (!url) return null
        const comp = Qt.createComponent(url, Component.PreferSynchronous)
        if (comp.status !== Component.Ready) {
          console.warn("dankshell: " + pluginId + " " + kind + " failed:", comp.errorString())
          return null
        }
        const obj = comp.createObject(host)
        if (!obj) { console.warn("dankshell: " + pluginId + " " + kind + " didn't start"); return null }
        // As Omarchy hands them over: only the properties the file declares.
        const all = Object.assign({ omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy" }, props)
        for (const k in all) if (k in obj) obj[k] = all[k]
        return obj
      }
      function sync() {
        if (wanted && !started) {
          started = true
          const kinds = Array.isArray(manifest.kinds) ? manifest.kinds : []
          if (kinds.indexOf("service") >= 0) service = make("service", { shell: shim, manifest: manifest })
          const mf = String(modelData.model || "")
          if (!service && mf && mf.indexOf("..") < 0)
            service = makeUrl("file://" + dir + "/" + mf, "model", { settings: settings, shell: shim, manifest: manifest })
          if (service && typeof service.applySettings === "function") service.applySettings(host.entrySettings(pluginId))
          const win = kinds.indexOf("panel") >= 0 ? "panel" : kinds.indexOf("overlay") >= 0 ? "overlay" : ""
          if (win) panel = make(win, { shell: shim, manifest: manifest, service: service })
        } else if (!wanted && started) {
          started = false
          if (panel) { panel.destroy(); panel = null }
          if (service) { service.destroy(); service = null }
        }
        const next = Object.assign({}, host.live)
        if (wanted && started) next[key] = h
        else delete next[key]
        host.live = next
      }
      function openPanel(id, payloadJson) {
        if (String(id || "") !== pluginId || !panel) return false
        if (typeof panel.open === "function") panel.open(payloadJson || "{}")
        else panel.opened = true
        return true
      }
      function closePanel(id) {
        if (String(id || "") !== pluginId || !panel) return false
        if (typeof panel.close === "function") panel.close()
        else panel.opened = false
        return true
      }

      readonly property FileView manifestFile: FileView {
        path: h.dir + "/manifest.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
          try {
            const m = JSON.parse(text())
            if (m && m.id === h.pluginId) h.manifest = m
          } catch (e) { console.warn("dankshell: " + h.pluginId + " manifest unreadable:", e) }
        }
        onLoadFailed: h.manifest = null
      }
      Component.onDestruction: {
        if (panel) panel.destroy()
        if (service) service.destroy()
      }
    }
  }
}
