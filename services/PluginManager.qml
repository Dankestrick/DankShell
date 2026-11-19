pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// PluginManager — install, update and remove plugins from the Plugins window
// (what Omaplug did). Everything runs through Omarchy's own `omarchy plugin`
// commands via scripts/plugin-manage. A job runs detached and writes its
// progress to ~/.cache/dankshell/plugin-job.json, so it keeps going even if the
// shell reloads plugins underneath it; this service watches that file.
Singleton {
  id: pm

  readonly property string script: Qt.resolvedUrl("../scripts/plugin-manage").toString().replace("file://", "")
  readonly property string jobFile: Quickshell.env("HOME") + "/.cache/dankshell/plugin-job.json"

  // ── Marketplace (loaded when the Get plugins page opens) ──
  property var catalog: []
  property bool catalogLoading: false
  property string catalogError: ""
  function loadCatalog() {
    if (catalogProc.running) return
    catalogLoading = true; catalogError = ""
    catalogProc.running = true
  }
  Process {
    id: catalogProc
    command: ["python3", "-I", pm.script, "catalog"]
    stdout: StdioCollector {
      onStreamFinished: {
        pm.catalogLoading = false
        try { pm.catalog = JSON.parse(text) || [] } catch (e) { pm.catalogError = "Couldn't read the plugin list" }
      }
    }
    onExited: (code) => { if (code !== 0) { pm.catalogLoading = false; pm.catalogError = "Couldn't reach plugins.omarchy.org" } }
  }
  function installed(id) { return Installed.all.some(p => p.id === id) }

  // ── Updates (checked when the Plugins window opens, at most every 15 min) ──
  property var updates: ({})          // id -> { git, update, note }
  property real checkedAt: 0
  property bool checking: false
  readonly property var updatable: Object.keys(updates).filter(id => updates[id].update)
  function checkUpdates(force) {
    if (checkProc.running || (!force && Date.now() - checkedAt < 15 * 60000)) return
    checking = true
    checkProc.running = true
  }
  Process {
    id: checkProc
    command: ["python3", "-I", pm.script, "check"]
    stdout: StdioCollector {
      onStreamFinished: {
        pm.checking = false
        try { pm.updates = JSON.parse(text) || {}; pm.checkedAt = Date.now() } catch (e) { }
      }
    }
    onExited: pm.checking = false
  }
  function hasUpdate(id) { return !!(updates[id] && updates[id].update) }
  function canRemove(p) { return !!p && !p.firstParty && p.id !== "io.github.dankestrick.dankshell" }

  // ── Jobs ──────────────────────────────────────
  property var job: ({})              // { state: running|done|failed, action, target, message }
  readonly property bool busy: job.state === "running" || starting
  property bool starting: false       // between the click and the job writing its file
  function start(action, arg) {
    if (busy) return
    starting = true
    startGuard.restart()
    Quickshell.execDetached(["python3", "-I", script, "run", action, arg])
  }
  Timer { id: startGuard; interval: 4000; onTriggered: pm.starting = false }
  function install(entry) { start("install", entry.url) }
  function update(id) { start("update", id) }
  function remove(id) { start("remove", id) }
  // "voiddropper.gifs" or a GitHub link -> a name to show
  function nameOf(target) {
    const bare = (u) => String(u).replace(/\.git\/?$/, "").replace(/\/$/, "").toLowerCase()
    const c = catalog.find(x => x.id === target || bare(x.url) === bare(target))
    const i = Installed.all.find(x => x.id === target)
    return c ? c.name : i ? i.name : String(target).replace(/^https:\/\/github\.com\//, "")
  }
  readonly property string jobText: {
    const j = job
    if (!j.state) return ""
    const what = nameOf(j.target)
    const verb = { install: ["Installing", "Installed", "Install"], update: ["Updating", "Updated", "Update"], remove: ["Removing", "Removed", "Remove"] }[j.action] || ["Working on", "Done with", "Job"]
    if (j.state === "running") return verb[0] + " " + what + "…"
    if (j.state === "done") return verb[1] + " " + what + "."
    return verb[2] + " of " + what + " didn't work" + (j.message ? ": " + j.message : "")
  }

  FileView {
    id: jobView
    path: pm.jobFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      let j = {}
      try { j = JSON.parse(text()) || {} } catch (e) { return }
      const was = pm.job.state
      const waiting = pm.starting
      pm.job = j
      if ((was === "running" || waiting) && j.state !== "running") {
        // finished: refresh the lists
        Installed.reload()
        if (j.action === "update" && j.state === "done") {
          const u = Object.assign({}, pm.updates); if (u[j.target]) u[j.target] = Object.assign({}, u[j.target], { update: false }); pm.updates = u
        }
      }
      pm.starting = false
    }
  }
  // The file has to exist before it can be watched.
  Process {
    running: true
    command: ["bash", "-c", "mkdir -p \"$HOME/.cache/dankshell\" && { [ -f \"$0\" ] || echo '{}' > \"$0\"; }", pm.jobFile]
    onExited: jobView.reload()
  }
}
