pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Notifications — your recent notifications for the Notifications page.
// Read from Omarchy's own files (~/.local/state/omarchy/notifications:
// live.json = on screen now, history.json = the last 30 that closed).
// Clearing is kept by DankShell in ~/.local/state/dankshell/notifications.json,
// so what you clear stays cleared (Omarchy's "show history" replays them all).
Singleton {
  id: n

  readonly property string omarchyDir: Quickshell.env("HOME") + "/.local/state/omarchy/notifications"
  readonly property string myDir: Quickshell.env("HOME") + "/.local/state/dankshell"

  property var history: []
  property var live: []

  // Newest first, minus anything cleared.
  readonly property var shown: {
    const seen = {}, out = []
    const cleared = state.clearedAt, gone = state.dismissed
    for (const e of live.concat(history)) {
      if (!e || !e.key || seen[e.key]) continue
      seen[e.key] = true
      if ((e.ts || 0) <= cleared || gone.indexOf(e.key) >= 0) continue
      out.push(e)
    }
    return out.sort((a, b) => (b.ts || 0) - (a.ts || 0))
  }
  readonly property int count: shown.length

  function dismiss(key) {
    state.dismissed = state.dismissed.filter(k => shown.some(e => e.key === k)).concat([key])
    save()
  }
  function clearAll() {
    state.clearedAt = Date.now() / 1000
    state.dismissed = []
    save()
    Quickshell.execDetached(["omarchy-shell", "notifications", "dismissAll"])
  }

  function ago(ts) {
    const s = Math.max(0, Date.now() / 1000 - ts)
    if (s < 60) return "now"
    if (s < 3600) return Math.floor(s / 60) + "m"
    if (s < 86400) return Math.floor(s / 3600) + "h"
    return Math.floor(s / 86400) + "d"
  }

  function parse(text) { try { const d = JSON.parse(text); return Array.isArray(d) ? d : [] } catch (e) { return [] } }

  FileView {
    path: n.omarchyDir + "/history.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: n.history = n.parse(text())
  }
  FileView {
    path: n.omarchyDir + "/live.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: n.live = n.parse(text())
  }

  // ── What you cleared ──────────────────────────
  function save() { mkdir.running = true }
  Process { id: mkdir; command: ["mkdir", "-p", n.myDir]; onExited: stateFile.writeAdapter() }
  FileView {
    id: stateFile
    path: n.myDir + "/notifications.json"
    printErrors: false
    JsonAdapter {
      id: state
      property real clearedAt: 0
      property var dismissed: []
    }
  }

  // "now", "5m"... stay fresh.
  property int tick: 0
  Timer { interval: 60000; repeat: true; running: true; onTriggered: n.tick++ }
}
