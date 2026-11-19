pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Eq — the global equalizer (scripts/eq). Settings live in
// ~/.config/dankshell/eq.json; the EQ itself is a PipeWire filter-chain sink
// ("DankShell EQ") that everything plays into, and it plays into your real
// output. Two layers: a headphone fix from AutoEq (per output) and your own
// 10 bands on top (±15 dB, presets, your own saved presets).
Singleton {
  id: eq

  readonly property string script: Qt.resolvedUrl("../scripts/eq").toString().replace("file://", "")
  readonly property string file: Quickshell.env("HOME") + "/.config/dankshell/eq.json"
  readonly property string sinkName: "dankshell_eq"
  readonly property var freqs: [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
  readonly property real range: 15

  // Built-in presets, gains for the 10 bands (31 Hz … 16 kHz).
  readonly property var builtIn: ({
    "Flat":          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "Hearing boost": [0, 0, 0, 0, 1, 3, 6, 8, 6, 3],
    "Footsteps":     [-4, -3, -2, 0, 1, 3, 6, 8, 5, 2],
    "Bass boost":    [8, 7, 5, 2, 0, 0, 0, 0, 0, 0],
    "Vocal":         [-2, -1, 0, 2, 4, 6, 5, 3, 0, -1]
  })

  // ── Settings ──────────────────────────────────
  property var data: ({})
  readonly property bool enabled: !!data.enabled
  readonly property var gains: (data.bands || []).length === 10 ? data.bands.map(b => Number(b.g) || 0) : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  readonly property string preset: data.preset || "Flat"
  readonly property var userPresets: data.presets || ({})
  readonly property var presetNames: Object.keys(builtIn).concat(Object.keys(userPresets).filter(k => !(k in builtIn)).sort())
  readonly property var headphones: data.headphones || ({})
  function headphonesFor(sinkName) { return headphones[sinkName] || null }

  function bandsFrom(g) {
    return freqs.map((f, i) => ({ f: f, g: Math.max(-range, Math.min(range, Number(g[i]) || 0)), q: i === 0 || i === 9 ? 0.7 : 0.9 }))
  }
  function save(next) {
    data = next
    store.setText(JSON.stringify(next, null, 1) + "\n")
  }
  FileView {
    id: store
    path: eq.file
    blockWrites: true              // written before scripts/eq reads it
    printErrors: false
    onLoaded: { try { eq.data = JSON.parse(text()) || {} } catch (e) { eq.data = {} } eq.loaded = true }
    onLoadFailed: eq.loaded = true
  }
  property bool loaded: false

  // ── Running state (scripts/eq status) ─────────
  property bool running: false
  property string target: ""
  property bool busy: false
  property string message: ""
  function refresh() { if (!statusProc.running) statusProc.running = true }
  Process {
    id: statusProc
    command: ["python3", "-I", eq.script, "status"]
    stdout: StdioCollector { onStreamFinished: { try { const st = JSON.parse(text); eq.running = !!st.running; eq.target = st.target || "" } catch (e) { } } }
  }

  // One script call at a time, in order.
  property var queue: []
  function run(args, after) { queue = queue.concat([{ args: args, after: after || null }]); pump() }
  function pump() {
    if (job.running || !queue.length) return
    const j = queue[0]; queue = queue.slice(1)
    job.after = j.after
    job.command = ["python3", "-I", script].concat(j.args)
    busy = true
    job.running = true
  }
  Process {
    id: job
    property var after: null
    stdout: StdioCollector { id: jobOut }
    stderr: StdioCollector { id: jobErr }
    onExited: (code) => {
      eq.busy = false
      eq.message = code === 0 ? "" : String(jobErr.text || "").trim().split("\n").pop()
      if (after) after(code, String(jobOut.text || "").trim())
      eq.refresh()
      eq.pump()
    }
  }

  // ── Turning it on and off ─────────────────────
  function setEnabled(on) {
    save(Object.assign({}, data, { enabled: on, bands: data.bands || bandsFrom(gains) }))
    run(on ? ["on"] : ["off"])
  }
  function retarget(sinkName) { run(["on", sinkName]) }
  function restartIfOn() { if (running) run(["on", target]) }

  // ── Bands ─────────────────────────────────────
  // Dragging changes the sound live (no restart); the file is saved when you let go.
  function setGain(i, g, final) {
    const next = gains.slice(); next[i] = Math.round(g * 2) / 2
    const d = Object.assign({}, data, { bands: bandsFrom(next), preset: "Custom" })
    data = d
    if (running) liveTimer.restart()
    if (final) save(d)
  }
  Timer { id: liveTimer; interval: 60; onTriggered: eq.run(["gains"].concat(eq.gains.map(String))) }
  function applyPreset(name) {
    const g = builtIn[name] || userPresets[name]
    if (!g) return
    save(Object.assign({}, data, { bands: bandsFrom(g), preset: name }))
    if (running) run(["gains"].concat(g.map(String)))
  }
  function savePreset(name) {
    name = String(name).trim()
    if (!name || name in builtIn) return
    const p = Object.assign({}, userPresets); p[name] = gains.slice()
    save(Object.assign({}, data, { presets: p, preset: name }))
  }
  function deletePreset(name) {
    if (!(name in userPresets)) return
    const p = Object.assign({}, userPresets); delete p[name]
    save(Object.assign({}, data, { presets: p, preset: preset === name ? "Custom" : preset }))
  }

  // ── Headphone fix (AutoEq) ────────────────────
  property var index: []              // [{ name, path, by }]
  property bool indexLoading: false
  function loadIndex() {
    if (index.length || indexProc.running) return
    indexLoading = true
    indexProc.running = true
  }
  Process {
    id: indexProc
    command: ["python3", "-I", eq.script, "index"]
    stdout: StdioCollector { onStreamFinished: { eq.indexLoading = false; try { eq.index = JSON.parse(text) || [] } catch (e) { } } }
    onExited: eq.indexLoading = false
  }
  function search(q) {
    q = String(q || "").trim().toLowerCase()
    if (q.length < 2) return []
    const words = q.split(/\s+/)
    return index.filter(e => words.every(w => e.name.toLowerCase().indexOf(w) >= 0)).slice(0, 12)
  }
  // Use an AutoEq profile for one output (the one playing now, by default).
  function pickHeadphones(entry, sinkName) {
    run(["fetch", entry.path], (code, out) => {
      if (code !== 0 || !out) return
      const h = Object.assign({}, headphones); h[sinkName] = { name: entry.name + " (" + entry.by.split(" on ")[0] + ")", file: out }
      save(Object.assign({}, data, { headphones: h }))
      restartIfOn()
    })
  }
  function clearHeadphones(sinkName) {
    const h = Object.assign({}, headphones); delete h[sinkName]
    save(Object.assign({}, data, { headphones: h }))
    restartIfOn()
  }

  // After a reboot or shell restart: turn the EQ back on if you left it on.
  property bool started: false
  Timer {
    interval: 3000; running: eq.loaded && !eq.started; repeat: false
    onTriggered: {
      eq.started = true
      eq.refresh()
      if (eq.enabled) startCheck.restart()
    }
  }
  Timer { id: startCheck; interval: 800; onTriggered: if (eq.enabled && !eq.running) eq.run(["on"]) }
}
