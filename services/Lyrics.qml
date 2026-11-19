pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Lyrics — synced lyrics for the Pandora song, from lrclib.net
// (scripts/lyrics.sh, carried over from DankBar). Reads the song and play
// position straight from OmaPandora's service (the Pandora page exists once
// per monitor, so pages pushing values in would fight), and gives back the
// lines and which one is being sung. The position only arrives about once a
// second, so it's smoothed in between while the song plays.
Singleton {
  id: ly

  // ── In: OmaPandora's service ──────────────────
  readonly property var svc: PluginHost.service("pandora")
  readonly property string artist: svc ? String(svc.artist || "") : ""
  readonly property string title: svc ? String(svc.title || "") : ""
  readonly property string album: svc ? String(svc.album || "") : ""
  readonly property real length: svc ? Number(svc.lengthSeconds || 0) : 0
  readonly property real reported: svc ? Number(svc.positionSeconds || 0) : 0
  readonly property bool playing: !!(svc && svc.playing)
  // Fetch only while a Pandora page is up (the service knows) and the card is open.
  readonly property bool watching: !!(svc && svc.uiVisible && svc.connected) && Settings.v.lyricsOpen

  // ── Out ───────────────────────────────────────
  property var lines: []           // [{ time, text }]
  property string state: "none"    // loading | ready | none
  property var match: null         // { title, artist, album } lrclib picked
  property real position: 0        // smoothed play position, seconds
  readonly property int current: {
    let i = -1
    for (let k = 0; k < lines.length; k++) { if (lines[k].time <= position + 0.15) i = k; else break }
    return i
  }

  // ── Fetch when the song changes (only while the page shows) ──
  property string fetchedKey: ""
  readonly property string key: watching && title ? artist + "\u0001" + title : ""
  onKeyChanged: debounce.restart()
  Timer {
    id: debounce
    interval: 400
    onTriggered: {
      if (!ly.key || ly.key === ly.fetchedKey) return
      ly.fetchedKey = ly.key
      ly.lines = []; ly.match = null; ly.state = "loading"
      probe.running = false
      probe.command = [Qt.resolvedUrl("../scripts/lyrics.sh").toString().replace("file://", ""),
        ly.artist, ly.title, ly.album, String(Math.round(ly.length > 0 && ly.length < 36000 ? ly.length : 0))]
      probe.running = true
    }
  }
  Process {
    id: probe
    stdout: StdioCollector {
      onStreamFinished: {
        const out = []
        let m = null
        for (const l of String(text).split("\n")) {
          if (l.startsWith("#match\t")) { const f = l.split("\t"); m = { title: f[1] || "", artist: f[2] || "", album: f[3] || "" }; continue }
          const r = l.match(/^\[(\d+):(\d+(?:\.\d+)?)\](.*)$/)
          if (r) out.push({ time: parseInt(r[1]) * 60 + parseFloat(r[2]), text: r[3].trim() })
        }
        ly.match = out.length ? m : null
        ly.lines = out
        ly.state = out.length ? "ready" : "none"
      }
    }
  }

  // ── Smooth position ───────────────────────────
  property real stamp: 0
  onReportedChanged: { position = reported; stamp = Date.now() }
  Timer {
    interval: 100; repeat: true
    running: ly.watching && ly.playing && ly.state === "ready"
    onTriggered: {
      const p = ly.reported + (Date.now() - ly.stamp) / 1000
      ly.position = ly.length > 0 ? Math.min(p, ly.length) : p
    }
  }
}
