pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons

// Sound — everything the Audio page shows and changes: outputs, inputs (with a
// live mic level), per-app volumes, mute-all, and the global EQ
// (scripts/eq: PipeWire filter-chain, AutoEq headphone fixes, your own bands).
//
// Carried over from Omarchy's audio panel (omarchy.audio), including its
// safety rules: lists hold plain {id, name} rows, never live PipeWire nodes
// (a node can vanish while a list is being drawn and take the shell with it),
// and a mic PipeWire can't type goes through Omarchy's UntypedInput (wpctl).
Singleton {
  id: s

  property bool watching: false        // the Audio page is showing (mic meter, EQ status)

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var nodeNames: nodes.map(n => n ? String(n.name || "") : "")
  function hides(n) { return !!n && AudioNodes.platformHides(n.name, nodeNames) }

  // ── Lists (live nodes, for trackers) ──────────
  readonly property var sinkNodes: nodes.filter(n => n && n.isSink && !n.isStream && !hides(n) && n.name !== Eq.sinkName)
  readonly property var sourceNodes: nodes.filter(n => n && !n.isSink && !n.isStream && !hides(n)
    && String(n.name || "") !== "quickshell" && !String(n.name || "").endsWith(".monitor")
    && (n.audio || String(n.type || "").indexOf("Source") >= 0 || String(n.name || "").startsWith("alsa_input")))
  readonly property var streamNodes: nodes.filter(n => n && n.isStream && n.isSink && !hides(n)
    && !String(n.name || "").startsWith(Eq.sinkName) && !String(n.name || "").startsWith("omarchy_speaker_tuning"))
  PwObjectTracker { objects: s.sinkNodes }
  PwObjectTracker { objects: s.sourceNodes }
  PwObjectTracker { objects: s.streamNodes }

  // ── Rows for the page (plain values only) ─────
  function props(n) { return n && n.ready && n.properties ? n.properties : {} }
  function label(text) {
    let t = String(text || "").trim()
    const bracket = t.match(/\[([^\]]+)\]\s*$/)              // "... (HDMI) [ES-G34C8]" -> the monitor's name
    if (bracket) return bracket[1]
    t = t.replace(/^built-?in audio\s+/i, "").replace(/\s+(Analog|Digital)?\s*(Stereo|Mono|Surround[\s\d.]*)(\s*\(.*\))?$/i, "")
    t = t.replace(/\s+(Output|Input)$/i, "")
    return t || String(text || "")
  }
  function nodeLabel(n) { const p = props(n); return label(n.nickname || p["node.nick"] || n.description || p["node.description"] || n.name) }
  function sinkIcon(n) {
    const blob = String([n.name, n.description, props(n)["device.icon-name"] || ""].join(" ")).toLowerCase()
    return /headphone|headset|earbud|kraken/.test(blob) ? "headphones" : /hdmi|displayport/.test(blob) ? "desktop_windows" : "speaker"
  }
  // The output really playing (the EQ plays into it when it's on).
  readonly property string realSinkName: Eq.running && Eq.target ? Eq.target : (sink ? String(sink.name || "") : "")
  readonly property var realSink: nodes.find(n => n && n.name === realSinkName && n.isSink && !n.isStream) || sink
  PwObjectTracker { objects: [s.realSink, s.source] }

  readonly property var outputs: sinkNodes.map(n => ({ id: n.id, name: String(n.name || ""), label: nodeLabel(n), icon: sinkIcon(n), on: n.name === realSinkName }))
  readonly property var inputs: sourceNodes.map(n => ({ id: n.id, name: String(n.name || ""), label: nodeLabel(n), on: !!source && n.id === source.id }))
  readonly property var streams: streamNodes.map(n => {
    const p = props(n)
    return { id: n.id, name: String(n.name || ""), label: String(p["application.name"] || n.description || p["media.name"] || n.name || "App"),
             volume: n.audio ? n.audio.volume : 0, muted: n.audio ? n.audio.muted : false }
  })
  function nodeFor(row) { return row ? nodes.find(n => n && n.id === row.id && String(n.name || "") === row.name) || null : null }

  // ── Output ────────────────────────────────────
  readonly property bool hasOutput: !!(realSink && realSink.audio)
  readonly property real outputVolume: hasOutput ? realSink.audio.volume : 0
  readonly property bool outputMuted: hasOutput ? realSink.audio.muted : false
  function setOutputVolume(v) { if (hasOutput) realSink.audio.volume = Math.max(0, Math.min(1.5, v)) }
  function toggleOutputMute() { if (hasOutput) realSink.audio.muted = !realSink.audio.muted }
  function useOutput(row) {
    const n = nodeFor(row)
    if (!n) return
    if (Eq.running) { Eq.retarget(n.name); return }   // the EQ follows to the new output
    Pipewire.preferredDefaultAudioSink = n
    Quickshell.execDetached(["omarchy-audio-output-set-default", String(n.id), String(n.name)])
  }
  // Omarchy's names for how loud it is (Model.js outputVolumeName).
  function volumeName(v, muted) {
    if (muted) return "Muted"
    const p = Math.round(v * 100)
    return p === 0 ? "Silenced" : p >= 100 ? "Concert hall" : p >= 85 ? "Party mode" : p >= 70 ? "Cranked up"
         : p >= 50 ? "Steady groove" : p >= 30 ? "Easy listening" : p >= 15 ? "Murmur" : "Whisper"
  }

  // ── Input ─────────────────────────────────────
  readonly property bool inputViaWpctl: UntypedInput.active
  readonly property bool hasInput: !!(source && source.audio) || (inputViaWpctl && UntypedInput.known)
  readonly property real inputVolume: inputViaWpctl ? UntypedInput.volume : (source && source.audio ? source.audio.volume : 0)
  readonly property bool inputMuted: inputViaWpctl ? UntypedInput.muted : (source && source.audio ? source.audio.muted : false)
  function setInputVolume(v) {
    v = Math.max(0, Math.min(1.5, v))
    if (inputViaWpctl) UntypedInput.setVolume(v)
    else if (source && source.audio) source.audio.volume = v
  }
  function toggleInputMute() {
    if (inputViaWpctl) { if (UntypedInput.known) UntypedInput.setMuted(!UntypedInput.muted) }
    else if (source && source.audio) source.audio.muted = !source.audio.muted
  }
  function useInput(row) {
    const n = nodeFor(row)
    if (!n) return
    if (n.audio) Pipewire.preferredDefaultAudioSource = n
    Quickshell.execDetached(["omarchy-audio-input-set-default", String(n.id), String(n.name)])
  }
  // Live mic level (typed mics only, like Omarchy's).
  PwNodePeakMonitor {
    id: peaks
    node: s.watching && s.source && s.source.audio ? s.source : null
    enabled: s.watching && !!s.source && !!s.source.audio
  }
  readonly property real micLevel: peaks.enabled ? peaks.peak : 0
  readonly property bool micLevelKnown: peaks.enabled

  // ── Per-app ───────────────────────────────────
  function setStreamVolume(row, v) { const n = nodeFor(row); if (n && n.audio) n.audio.volume = Math.max(0, Math.min(1.5, v)) }
  function toggleStreamMute(row) { const n = nodeFor(row); if (n && n.audio) n.audio.muted = !n.audio.muted }

  // ── Everything on/off (Omarchy's header switch) ──
  readonly property bool anyAudible: (hasOutput && !outputMuted) || (hasInput && !inputMuted)
  function toggleAll() {
    const mute = anyAudible
    if (hasOutput) realSink.audio.muted = mute
    if (hasInput && inputViaWpctl) UntypedInput.setMuted(mute)
    else if (hasInput) source.audio.muted = mute
  }

  // ── The EQ follows when the output changes somewhere else ──
  // (keys, Omarchy's own panel, a headset turning on): if the EQ is on and the
  // default output moves to a real device, play the EQ into that device and
  // make the EQ the default again.
  Connections {
    target: Pipewire
    function onDefaultAudioSinkChanged() { follow.restart() }
  }
  Timer {
    id: follow
    interval: 900
    onTriggered: {
      const n = Pipewire.defaultAudioSink
      if (!Eq.enabled || !Eq.running || !n || Eq.busy) return
      const name = String(n.name || "")
      if (name && name !== Eq.sinkName && name !== Eq.target) Eq.retarget(name)
    }
  }
}
