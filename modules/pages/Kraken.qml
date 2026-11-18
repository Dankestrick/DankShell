import QtQuick
import "../../"

// Kraken — OmaKraken (Razer Kraken V3 Pro) as a dashboard page: battery,
// lighting, sidetone, mic, haptics, power saving. Every change goes through
// OmaKraken's own service and helper (PluginHost runs them); this is the look.
Column {
  id: page
  spacing: 10

  readonly property var service: PluginHost.service("kraken")
  readonly property var status: service ? service.status || {} : ({})
  readonly property var saved: service ? service.saved || {} : ({})
  readonly property bool dongle: !!(service && service.dongle)
  readonly property bool connected: !!(service && service.connected)
  readonly property bool charging: !!(service && service.charging)
  readonly property int battery: service ? service.battery : -1
  readonly property string effect: saved.effect || "static"
  readonly property bool lightingOn: saved.lighting !== false
  // The headset turns its lights off while charging, whatever is sent.
  readonly property bool lightsLive: connected && !charging && lightingOn

  readonly property var effects: [
    { value: "static", label: "Static" }, { value: "breathing", label: "Breathing" }, { value: "spectrum", label: "Spectrum" }
  ]
  readonly property var colours: ["#ff0000", "#ff9933", "#ffff00", "#00ff00", "#00ffff", "#0000ff", "#601986", "#ff00ff", "#e4007f", "#ffffff"]

  function set(key, value) { if (service) service.change(key, value) }

  // While the page is showing, the helper checks the headset more often.
  property bool showing: false
  onShowingChanged: if (service) service.panelOpen = showing
  onServiceChanged: if (service) service.panelOpen = showing

  Text {
    visible: !page.service
    width: parent.width
    wrapMode: Text.WordWrap
    text: "Kraken is still running on Omarchy's side. Run `dankshell on` to hand it to DankShell."
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12
  }

  Card {
    visible: !!page.service
    width: parent.width
    DeviceHeader {
      icon: "headphones"
      title: "Kraken V3 Pro"
      subtitle: page.service ? page.service.batteryText : "Starting"
      active: page.connected
      trailingIcon: !page.connected || page.battery < 0 ? "" : page.charging ? "battery_charging_full" : page.battery <= 10 ? "battery_alert" : page.battery <= 40 ? "battery_3_bar" : "battery_full"
      trailingColor: page.battery <= 20 && !page.charging ? Theme.urgent : Theme.accent
    }
  }

  // Lighting
  Card {
    visible: page.connected
    width: parent.width
    SwitchRow {
      icon: "light_mode"; label: "Lighting"
      sub: page.charging ? "Off while charging" : ""
      checked: page.lightingOn
      disabled: page.charging
      onToggled: (v) => page.set("lighting", v)
    }
    Chips {
      model: page.effects.map(e => e.label)
      current: page.effects.findIndex(e => e.value === page.effect)
      enabled: page.lightsLive
      onPicked: (i) => page.set("effect", page.effects[i].value)
    }
    SliderRow {
      icon: "brightness_6"
      enabled: page.lightsLive
      value: (page.saved.brightness !== undefined ? page.saved.brightness : 100) / 100
      text: (page.saved.brightness !== undefined ? page.saved.brightness : 100) + "%"
      onMoved: (v) => page.set("brightness", Math.round(v * 100))
    }
    SliderRow {
      visible: page.effect === "breathing" || page.effect === "spectrum"
      icon: "speed"
      enabled: page.lightsLive
      value: ((page.saved.speed || 5) - 1) / 9
      text: String(page.saved.speed || 5)
      onMoved: (v) => page.set("speed", 1 + Math.round(v * 9))
    }
    Swatches {
      visible: page.effect === "static" || page.effect === "breathing"
      enabled: page.lightsLive
      colours: page.colours
      current: page.saved.color || ""
      onPicked: (c) => page.set("color", c)
    }
  }

  // Sidetone + mic
  Card {
    visible: page.connected
    width: parent.width
    SwitchRow {
      icon: "hearing"; label: "Sidetone"
      sub: "Hear your own voice"
      checked: !!page.status.sidetone
      onToggled: (v) => page.set("sidetone", v)
    }
    SliderRow {
      icon: "graphic_eq"
      enabled: !!page.status.sidetone
      value: (page.status.sidetoneLevel || 0) / 4
      text: String((page.status.sidetoneLevel || 0) + 1)
      onMoved: (v) => page.set("sidetoneLevel", Math.round(v * 4))
    }
    SliderRow {
      visible: !!page.service && page.service.micVolume >= 0
      icon: page.service && page.service.micMuted ? "mic_off" : "mic"
      iconClick: true
      live: true
      value: page.service ? Math.max(0, page.service.micVolume) : 0
      text: page.service ? Math.round(Math.max(0, page.service.micVolume) * 100) + "%" : ""
      onMoved: (v) => page.service.setMicVolume(v)
      onIconClicked: page.service.toggleMicMute()
    }
  }

  // Haptics + power saving
  Card {
    visible: page.connected
    width: parent.width
    SwitchRow {
      icon: "vibration"; label: "Haptics"
      checked: page.saved.haptics !== false
      onToggled: (v) => page.set("haptics", v)
    }
    Chips {
      model: ["Low", "Medium", "High"]
      current: (page.saved.hapticsLevel || 2) - 1
      enabled: page.saved.haptics !== false
      onPicked: (i) => page.set("hapticsLevel", i + 1)
    }
    SwitchRow {
      icon: "energy_savings_leaf"; label: "Power saving"
      sub: page.status.powerSaving ? "Off after " + (page.status.powerSavingMinutes || 15) + " min idle" : ""
      checked: !!page.status.powerSaving
      onToggled: (v) => page.set("powerSaving", v)
    }
    SliderRow {
      icon: "timer"
      enabled: !!page.status.powerSaving
      value: ((page.status.powerSavingMinutes || 15) - 15) / 45
      text: (page.status.powerSavingMinutes || 15) + "m"
      onMoved: (v) => page.set("powerSavingMinutes", 15 + Math.round(v * 45))
    }
  }

  // Not connected
  Card {
    visible: !!page.service && !page.connected
    width: parent.width
    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      text: !page.dongle ? "Plug in the Kraken's USB dongle." : "Turn the headset on, or move it closer to the dongle."
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12
    }
    RoundButton { anchors.right: parent.right; icon: "refresh"; onClicked: page.service.refresh() }
  }
}
