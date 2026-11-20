pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// PluginManager — update and remove plugins from the Plugins window (what
// Omaplug did), and update git installs (God's Eye View, ComfyUI, CloneWars). Everything runs through Omarchy's own `omarchy plugin`
// commands via scripts/plugin-manage. A job runs detached and writes its
// progress to ~/.cache/dankshell/plugin-job.json, so it keeps going even if the
// shell reloads plugins underneath it; this service watches that file.
Singleton {
  id: pm

  readonly property string script: Qt.resolvedUrl("../scripts/plugin-manage").toString().replace("file://", "")
  readonly property string jobFile: Quickshell.env("HOME") + "/.cache/dankshell/plugin-job.json"


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
  // ── Git installs (checked with the plugins) ──
  property var gitInstalls: []        // [{ path, name, branch, behind, update, note, last }]
  property real gitCheckedAt: 0
  property bool gitChecking: false
  readonly property var gitUpdatable: gitInstalls.filter(g => g.update)
  function gitCheck(force) {
    if (gitProc.running || (!force && Date.now() - gitCheckedAt < 15 * 60000)) return
    gitChecking = true
    gitProc.running = true
  }
  Process {
    id: gitProc
    command: ["python3", "-I", pm.script, "gitcheck"]
    stdout: StdioCollector {
      onStreamFinished: {
        pm.gitChecking = false
        try { pm.gitInstalls = JSON.parse(text) || []; pm.gitCheckedAt = Date.now() } catch (e) { }
      }
    }
    onExited: pm.gitChecking = false
  }
  function checkAll(force) { checkUpdates(force); gitCheck(force) }

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
  // items: ["plugin:<id>", "git:<path>", …], updated one after another
  function updateMany(items) {
    if (busy || !items.length) return
    starting = true
    startGuard.restart()
    Quickshell.execDetached(["python3", "-I", script, "batch"].concat(items))
  }
  function update(id) { start("update", id) }
  function remove(id) { start("remove", id) }
  // "voiddropper.gifs" or a GitHub link -> a name to show
  function nameOf(target) {
    const bare = (u) => String(u).replace(/\.git\/?$/, "").replace(/\/$/, "").toLowerCase()
    const i = Installed.all.find(x => x.id === target)
    return i ? i.name : String(target).replace(/^https:\/\/github\.com\//, "")
  }
  readonly property string jobText: {
    const j = job
    if (!j.state) return ""
    if (j.action === "batch") {
      const items = j.items || []
      const name = (it) => it.kind === "plugin" ? nameOf(it.target) : it.name
      if (j.state === "running") {
        const cur = items.findIndex(it => it.state === "running")
        return "Updating " + (items.length > 1 ? (cur + 1) + " of " + items.length + ": " : "") + (cur >= 0 ? name(items[cur]) : "") + "…"
      }
      const ok = items.filter(it => it.state === "done"), bad = items.filter(it => it.state === "failed")
      const parts = []
      if (ok.length) parts.push("Updated " + ok.map(it => name(it) + (it.message && it.kind === "git" ? " (" + it.message + ")" : "")).join(", ") + ".")
      for (const it of bad) parts.push(name(it) + " didn't update" + (it.message ? ": " + it.message : "") + ".")
      return parts.join("  ") || (j.message || "")
    }
    const what = nameOf(j.target)
    const verb = { install: ["Installing", "Installed", "Install"], update: ["Updating", "Updated", "Update"], remove: ["Removing", "Removed", "Remove"] }[j.action] || ["Working on", "Done with", "Job"]
    if (j.state === "running") return verb[0] + " " + what + "…"
    if (j.state === "done") return verb[1] + " " + what + "."
    return verb[2] + " of " + what + " didn't work" + (j.message ? ": " + j.message : "")
  }

  function markUpdated(kind, target) {
    if (kind === "plugin") {
      const u = Object.assign({}, updates); if (u[target]) u[target] = Object.assign({}, u[target], { update: false }); updates = u
    } else {
      gitInstalls = gitInstalls.map(g => g.path === target ? Object.assign({}, g, { update: false, behind: 0, note: "" }) : g)
    }
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
        if (j.action === "update" && j.state === "done") pm.markUpdated("plugin", j.target)
        if (j.action === "batch")
          for (const it of j.items || []) if (it.state === "done") pm.markUpdated(it.kind, it.target)
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
