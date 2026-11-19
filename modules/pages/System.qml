import QtQuick
import "../../"

// System — the Device window's Bluetooth page: click a device to connect or
// disconnect it. (Sound moved to the Audio page, modules/pages/Audio.qml.)
Column {
  id: sys
  spacing: 6

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
