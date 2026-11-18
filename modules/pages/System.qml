import QtQuick
import Quickshell.Services.Pipewire
import "../../"

// System — where sound goes and which Bluetooth devices are connected.
// Click a speaker/headset to make it the output. Click a Bluetooth device
// to connect or disconnect it.
Column {
  id: sys
  spacing: 6

  // ── Sound output ──────────────────────────────
  SectionLabel { text: "Sound output" }

  Repeater {
    model: Audio.outputs
    ListRow {
      required property var modelData
      width: sys.width
      icon: (modelData.description || "").toLowerCase().includes("hdmi") ? "tv"
          : (modelData.description || "").toLowerCase().includes("kraken") || (modelData.description || "").toLowerCase().includes("headset") ? "headphones"
          : "speaker"
      title: modelData.description || modelData.name
      active: Audio.sink === modelData
      status: active ? Math.round(Audio.volume * 100) + "%" : ""
      onClicked: Audio.useOutput(modelData)
    }
  }

  Item { width: 1; height: 6 }

  // ── Bluetooth ─────────────────────────────────
  SectionLabel { text: Toggles.bluetooth ? "Bluetooth" : "Bluetooth (off)" }

  Repeater {
    model: Toggles.btDevices
    ListRow {
      required property var modelData
      width: sys.width
      icon: (modelData.icon || "").includes("headset") || (modelData.icon || "").includes("audio") ? "headphones"
          : (modelData.icon || "").includes("gam") ? "sports_esports"
          : (modelData.icon || "").includes("phone") ? "smartphone"
          : (modelData.icon || "").includes("mouse") ? "mouse"
          : (modelData.icon || "").includes("keyboard") ? "keyboard"
          : "bluetooth"
      title: modelData.name || modelData.address
      active: modelData.connected
      status: modelData.connected
        ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "Connected")
        : "Tap to connect"
      onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
    }
  }

  Text {
    visible: Toggles.btDevices.length === 0
    text: Toggles.bluetooth ? "No paired devices" : "Turn Bluetooth on from Home"
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 11
    leftPadding: 10
  }

  component SectionLabel: Text {
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 10
    font.weight: Font.DemiBold
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 0.8
    leftPadding: 4
    bottomPadding: 2
  }
}
