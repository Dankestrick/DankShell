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

  // What you cleared: everything up to clearedAt, plus single ones by key.
  property real clearedAt: 0
  property var dismissed: []

  // Newest first, minus anything cleared.
  readonly property var shown: {
    const seen = {}, out = []
    for (const e of live.concat(history)) {
      if (!e || !e.key || seen[e.key]) continue
      seen[e.key] = true
      if ((e.ts || 0) <= clearedAt || dismissed.indexOf(e.key) >= 0) continue
      out.push(e)
    }
    return out.sort((a, b) => (b.ts || 0) - (a.ts || 0))
  }
  readonly property int count: shown.length

  function dismiss(key) {
    // Keep only keys Omarchy still has, so the list doesn't grow forever.
    const known = live.concat(history).map(e => e && e.key)
    dismissed = dismissed.filter(k => k !== key && known.indexOf(k) >= 0).concat([key])
    save()
  }
  function clearAll() {
    clearedAt = Date.now() / 1000
    dismissed = []
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

  // ── Saving what you cleared ───────────────────
  function save() { mkdir.running = true }
  Process {
    id: mkdir
    command: ["mkdir", "-p", n.myDir]
    onExited: stateFile.setText(JSON.stringify({ clearedAt: n.clearedAt, dismissed: n.dismissed }) + "\n")
  }
  FileView {
    id: stateFile
    path: n.myDir + "/notifications.json"
    printErrors: false
    onLoaded: {
      try {
        const d = JSON.parse(text())
        n.clearedAt = Number(d.clearedAt) || 0
        n.dismissed = Array.isArray(d.dismissed) ? d.dismissed : []
      } catch (e) { }
    }
  }

  // "now", "5m"... stay fresh.
  property int tick: 0
  Timer { interval: 60000; repeat: true; running: true; onTriggered: n.tick++ }
}
