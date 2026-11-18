pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Audio — the speaker/headset volume (whatever PipeWire's default output is).
Singleton {
  id: audio

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink !== null && sink.audio !== null
  readonly property real volume: ready ? sink.audio.volume : 0
  readonly property bool muted: ready ? sink.audio.muted : false
  readonly property string name: sink ? (sink.description || sink.name || "") : ""

  function setVolume(v) { if (ready) sink.audio.volume = Math.max(0, Math.min(1, v)) }
  function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted }

  // PipeWire only fills in volume for objects someone is watching.
  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
}
