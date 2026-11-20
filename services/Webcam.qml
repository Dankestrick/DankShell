pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Webcam — the Anker PowerConf C200 for the Camera page. Finds it by name
// (never a fixed /dev/videoN), reads its controls, sets them with v4l2-ctl
// (scripts/camera), keeps saved looks in ~/.config/dankshell/camera.json and
// puts the active look back when the camera is plugged in.
// Separate from the DSLR webcam plugin (Canon, v4l2loopback): never touches it.
Singleton {
  id: cam

  readonly property string helper: Qt.resolvedUrl("../scripts/camera").toString().replace("file://", "")
  readonly property string name: "Anker PowerConf C200"
  readonly property string lookFile: Quickshell.env("HOME") + "/.config/dankshell/camera.json"

  property string device: ""             // /dev/videoN, "" when unplugged
  readonly property bool present: device !== ""
  property var ctrls: ({})               // name -> { min, max, step, def, value, inactive }
  property bool exposureStuck: false     // this camera won't go back to auto exposure until replugged

  // Saved looks: { active: "Desk", size: "1920x1080", looks: { Desk: { brightness: 25, ... } } }
  property var data: ({ active: "", size: "1920x1080", looks: {} })
  readonly property var looks: data.looks || ({})
  readonly property var lookNames: Object.keys(looks).sort()
  readonly property string activeLook: data.active || ""
  readonly property string bigSize: data.size || "1920x1080"

  // Order matters: an auto switch goes first, so the manual value after it sticks.
  readonly property var order: ["white_balance_automatic", "focus_automatic_continuous", "auto_exposure",
    "brightness", "contrast", "saturation", "sharpness", "gamma", "hue", "power_line_frequency",
    "white_balance_temperature", "exposure_time_absolute", "focus_absolute",
    "zoom_absolute", "pan_absolute", "tilt_absolute"]

  function c(n) { return ctrls[n] || null }
  function val(n) { return ctrls[n] ? ctrls[n].value : 0 }
  readonly property bool autoWhite: val("white_balance_automatic") === 1
  readonly property bool autoFocus: val("focus_automatic_continuous") === 1
  readonly property bool autoExposure: !!ctrls.auto_exposure && val("auto_exposure") !== 1

  // ── Reading ───────────────────────────────────
  property bool applyAfterFind: false
  function refresh() { if (!reader.running) reader.running = true }
  Process {
    id: reader
    command: ["bash", "-c", "d=$('" + cam.helper + "' find); echo \"DEV=$d\"; [ -n \"$d\" ] && '" + cam.helper + "' ctrls \"$d\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = {}
        let dev = ""
        for (const line of text.split("\n")) {
          if (line.startsWith("DEV=")) { dev = line.slice(4).trim(); continue }
          const m = line.match(/^\s*(\w+) 0x[0-9a-f]+ \((\w+)\)\s*:\s*(.*)$/)
          if (!m) continue
          const o = { type: m[2], inactive: /flags=.*inactive/.test(m[3]) }
          const re = /(\w+)=(-?\d+)/g
          let kv
          while ((kv = re.exec(m[3])) !== null) o[kv[1] === "default" ? "def" : kv[1]] = Number(kv[2])
          if (o.type === "bool") { o.min = 0; o.max = 1; o.step = 1 }
          out[m[1]] = o
        }
        const wasThere = cam.present
        cam.device = dev
        cam.ctrls = out
        if (!dev) cam.exposureStuck = false
        if (dev && cam.applyAfterFind) { cam.applyAfterFind = false; if (cam.activeLook) cam.applyLook(cam.activeLook) }
      }
    }
  }

  // ── Changing (sliders send many values; only the newest of each goes out) ──
  property var pending: ({})
  function set(n, v) {
    if (!ctrls[n]) return
    const copy = Object.assign({}, ctrls)
    copy[n] = Object.assign({}, copy[n], { value: v })
    ctrls = copy
    const p = Object.assign({}, pending); p[n] = v; pending = p
    pump()
  }
  function pump() {
    if (writer.running || !present) return
    const keys = order.filter(k => k in pending)
    if (!keys.length) return
    writer.touchedAuto = keys.some(k => k.indexOf("auto") >= 0)
    writer.wantedAutoExposure = ("auto_exposure" in pending) && pending.auto_exposure !== 1
    writer.command = [helper, "set", device].concat(keys.map(k => k + "=" + pending[k]))
    pending = ({})
    writer.running = true
  }
  Process {
    id: writer
    property bool touchedAuto: false
    property bool wantedAutoExposure: false
    onExited: (code) => {
      if (wantedAutoExposure && code !== 0) cam.exposureStuck = true
      if (touchedAuto) cam.refresh()   // the manual sliders turn on/off
      cam.pump()
    }
  }

  // Turn exposure auto on/off. On this camera auto only comes back on a replug.
  function setAutoExposure(on) { set("auto_exposure", on ? 0 : 1) }

  // ── Looks ─────────────────────────────────────
  function snapshot() {
    const out = {}
    for (const k of order) if (ctrls[k]) out[k] = ctrls[k].value
    return out
  }
  // Put a set of values on the camera, skipping manual values whose auto is on
  // (and auto exposure, which this camera only gets back from a replug).
  function applyValues(vals) {
    const p = Object.assign({}, pending)
    for (const k of order) {
      if (!(k in vals) || !ctrls[k]) continue
      if (k === "auto_exposure" && vals[k] !== 1) continue
      if (k === "white_balance_temperature" && vals.white_balance_automatic === 1) continue
      if (k === "focus_absolute" && vals.focus_automatic_continuous === 1) continue
      if (k === "exposure_time_absolute" && vals.auto_exposure !== 1) continue
      p[k] = vals[k]
    }
    pending = p
    pump()
  }
  function applyLook(n) {
    if (!looks[n]) return
    applyValues(looks[n])
    write(Object.assign({}, data, { active: n }))
  }
  function saveLook(n) {
    n = String(n).trim()
    if (!n) return
    const l = Object.assign({}, looks); l[n] = snapshot()
    write(Object.assign({}, data, { looks: l, active: n }))
  }
  function deleteLook(n) {
    const l = Object.assign({}, looks); delete l[n]
    write(Object.assign({}, data, { looks: l, active: data.active === n ? "" : data.active }))
  }
  function resetDefaults() {
    const vals = {}
    for (const k of order) if (ctrls[k] && ctrls[k].def !== undefined) vals[k] = ctrls[k].def
    applyValues(vals)
  }
  function setBigSize(s) { write(Object.assign({}, data, { size: s })) }

  function write(d) { data = d; file.setText(JSON.stringify(d, null, 2) + "\n") }
  FileView {
    id: file
    path: cam.lookFile
    printErrors: false
    onLoaded: { try { const d = JSON.parse(text()); if (d && typeof d === "object") cam.data = Object.assign({ active: "", size: "1920x1080", looks: {} }, d) } catch (e) { } }
  }

  // ── Plug-in watch: udev says a video device came or went ──
  Process {
    id: udev
    running: true
    command: ["udevadm", "monitor", "--udev", "--subsystem-match=video4linux"]
    stdout: SplitParser {
      onRead: (line) => {
        if (/\badd\b/.test(line)) { cam.applyAfterFind = true; settle.restart() }
        else if (/\bremove\b/.test(line)) settle.restart()
      }
    }
    onRunningChanged: if (!running) again.start()
  }
  Timer { id: again; interval: 5000; onTriggered: udev.running = true }
  Timer { id: settle; interval: 1500; onTriggered: cam.refresh() }   // the camera needs a moment after plug-in

  // ── Open big: mpv fullscreen (Esc leaves fullscreen, q closes; the page preview lets go of the camera meanwhile) ──
  property bool wantBig: false
  readonly property bool bigOpen: wantBig || big.running
  function openBig() {
    if (!present || bigOpen) return
    wantBig = true      // the preview lets go first
    bigWait.restart()
  }
  Timer { id: bigWait; interval: 600; onTriggered: cam.launchBig() }
  Timer { id: bigCheck; interval: 3000; onTriggered: if (!big.running) cam.wantBig = false }  // mpv never started
  function launchBig() {
    if (!present) { wantBig = false; return }
    bigCheck.restart()
    big.command = ["mpv", "--title=Camera", "--fs", "--profile=low-latency", "--untimed", "--no-osc",
                   "--demuxer-lavf-format=video4linux2",
                   "--demuxer-lavf-o=video_size=" + bigSize + ",input_format=mjpeg",
                   "av://v4l2:" + device]
    big.running = true
  }
  function closeBig() { if (big.running) big.signal(15) }
  Process { id: big; onRunningChanged: if (!running) cam.wantBig = false }

  Component.onCompleted: refresh()
}
