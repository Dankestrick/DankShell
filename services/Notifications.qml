pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Notifications — your notifications for the Notifications window, in three
// stages: Unread (today), Read (today) and Archive (from before midnight).
// They come from Omarchy's own files (~/.local/state/omarchy/notifications:
// live.json = on screen now, history.json = closed in the last 24 hours), so
// they last as long as Omarchy keeps them. DankShell only remembers which ones
// you read or deleted: ~/.local/state/dankshell/notifications.json.
Singleton {
  id: n

  readonly property string omarchyDir: Quickshell.env("HOME") + "/.local/state/omarchy/notifications"
  readonly property string myDir: Quickshell.env("HOME") + "/.local/state/dankshell"

  property var history: []
  property var live: []

  property var readKeys: []      // ones you read
  property var dismissed: []     // ones you deleted
  property real clearedAt: 0     // everything up to here counts as read (older DankShell's "Clear all")

  // Every notification Omarchy still has, newest first, minus deleted ones.
  readonly property var all: {
    const seen = {}, out = []
    for (const e of live.concat(history)) {
      if (!e || !e.key || seen[e.key] || dismissed.indexOf(e.key) >= 0) continue
      seen[e.key] = true
      out.push({
        key: e.key,
        app: String(e.app || e.source || ""),
        glyph: String(e.glyph || ""),
        summary: String(e.summary || ""),
        body: String(e.body || e.bodyLine || "").replace(/<[^>]*>/g, ""),
        urgency: Number(e.urgency) || 0,
        ts: Number(e.ts) || 0,
        read: (Number(e.ts) || 0) <= clearedAt || readKeys.indexOf(e.key) >= 0
      })
    }
    return out.sort((a, b) => b.ts - a.ts)
  }

  // ── The three stages ──────────────────────────
  property int tick: 0   // bumps every minute ("5m", and midnight moves today's into the archive)
  readonly property real todayStart: { void(tick); const d = new Date(); d.setHours(0, 0, 0, 0); return d.getTime() / 1000 }
  readonly property var unread: all.filter(e => !e.read && e.ts >= todayStart)
  readonly property var read: all.filter(e => e.read && e.ts >= todayStart)
  readonly property var archive: all.filter(e => e.ts < todayStart)
  function stage(name) { return name === "read" ? read : name === "archive" ? archive : unread }

  // The dashboard's count (and the dot) = unread.
  readonly property int count: unread.length
  readonly property var shown: unread

  // ── Doing things ──────────────────────────────
  // Keep only keys Omarchy still has, so the lists don't grow forever.
  function trim(list) { const known = live.concat(history).map(e => e && e.key); return list.filter(k => known.indexOf(k) >= 0) }
  function markRead(key) {
    if (readKeys.indexOf(key) >= 0) return
    readKeys = trim(readKeys).concat([key])
    save()
  }
  function markAllRead() {
    readKeys = trim(readKeys).concat(unread.map(e => e.key))
    save()
    Quickshell.execDetached(["omarchy-shell", "notifications", "dismissAll"])   // the ones still on screen go too
  }
  function remove(key) {
    dismissed = trim(dismissed).concat([key])
    save()
  }
  function removeAll(name) {
    dismissed = trim(dismissed).concat(stage(name).map(e => e.key))
    save()
  }
  // Older names, still used around DankShell.
  function dismiss(key) { remove(key) }
  function clearAll() { markAllRead() }

  function ago(ts) {
    void(tick)
    const s = Math.max(0, Date.now() / 1000 - ts)
    if (s < 60) return "now"
    if (s < 3600) return Math.floor(s / 60) + "m"
    if (s < 86400) return Math.floor(s / 3600) + "h"
    return Math.floor(s / 86400) + "d"
  }
  function clock(ts) { return Qt.formatTime(new Date(ts * 1000), "h:mm AP") }

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

  // ── Saving what you read and deleted ──────────
  function save() { mkdir.running = true }
  Process {
    id: mkdir
    command: ["mkdir", "-p", n.myDir]
    onExited: stateFile.setText(JSON.stringify({ clearedAt: n.clearedAt, read: n.readKeys, dismissed: n.dismissed }) + "\n")
  }
  FileView {
    id: stateFile
    path: n.myDir + "/notifications.json"
    printErrors: false
    onLoaded: {
      try {
        const d = JSON.parse(text())
        n.clearedAt = Number(d.clearedAt) || 0
        n.readKeys = Array.isArray(d.read) ? d.read : []
        n.dismissed = Array.isArray(d.dismissed) ? d.dismissed : []
      } catch (e) { }
    }
  }

  Timer { interval: 60000; repeat: true; running: true; onTriggered: n.tick++ }
}
