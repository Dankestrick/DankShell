import QtQuick
import "../../"

// Gravastar — OmaGravastar (Mercury X Pro mouse) as a dashboard page: DPI
// stages, polling rate, lighting. Buttons and macros stay in OmaGravastar's
// own big window (the two buttons at the bottom open it). Every change goes
// through OmaGravastar's service and helper; this is only the look.
Column {
  id: page
  spacing: 10
  signal closeRequested()

  readonly property var service: PluginHost.service("gravastar")
  readonly property var hosted: PluginHost.hosted("gravastar")
  readonly property var s: service && service.mouseSettings ? service.mouseSettings : ({})
  readonly property var light: s.lighting || ({})
  readonly property bool connected: !!(service && service.connected)
  readonly property bool awake: !!(service && service.awake)
  readonly property bool canEdit: connected && awake && s.pollingHz !== undefined
  readonly property int battery: service ? service.battery : -1
  readonly property bool charging: !!(service && service.charging)

  readonly property var effects: [
    { value: "off", label: "Off" }, { value: "rainbow", label: "Rainbow" },
    { value: "single-color-breath", label: "Breath" }, { value: "fixed-color", label: "Fixed" },
    { value: "neon", label: "Neon" }, { value: "rainbow-breath", label: "Rainbow Breath" }, { value: "fixed-rainbow", label: "Fixed Rainbow" }
  ]
  readonly property string effect: {
    const l = String(light.effect || "")
    const all = [["Single Color Breath", "single-color-breath"], ["Fixed Color", "fixed-color"]]
    for (const a of all) if (a[0] === l) return a[1]
    const e = effects.find(x => x.label === l || x.value === l)
    return e ? e.value : "off"
  }
  readonly property var polling: [["125", "125"], ["250", "250"], ["500", "500"], ["1000", "1K"], ["2000", "2K"], ["4000", "4K"], ["8000", "8K"]]
  readonly property var colours: ["#ff0000", "#00ffff", "#00ff00", "#ff00ff", "#ffff00", "#ff4500", "#0000ff", "#e4007f", "#601986", "#ffffff"]
  readonly property var stages: s.dpiStages || []
  readonly property int activeStage: s.activeStage || 1

  function send(args) { if (service && canEdit) service.change(args) }
  function onOff(v) { return v ? "on" : "off" }

  // While the page is showing, the service checks the mouse every 3s.
  property bool showing: false
  onShowingChanged: if (service) service.panelOpen = showing
  onServiceChanged: if (service) service.panelOpen = showing

  Text {
    visible: !page.service
    width: parent.width
    wrapMode: Text.WordWrap
    text: "Gravastar is still running on Omarchy's side. Run `dankshell on` to hand it to DankShell."
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12
  }

  Card {
    visible: !!page.service
    width: parent.width
    DeviceHeader {
      icon: "mouse"
      title: "Mercury X Pro"
      subtitle: {
        if (!page.connected) return "Dongle not found"
        const p = []
        if (page.battery >= 0) p.push(page.battery + "%")
        if (page.charging) p.push("Charging")
        if (!page.awake) p.push("Asleep, move the mouse")
        return p.join(" · ")
      }
      active: page.connected && page.awake
      trailingIcon: page.battery < 0 ? "" : page.charging ? "battery_charging_full" : page.battery <= 15 ? "battery_alert" : page.battery <= 40 ? "battery_3_bar" : "battery_full"
      trailingColor: page.battery <= 25 && !page.charging ? Theme.urgent : Theme.accent
    }
  }

  // DPI + polling
  Card {
    visible: page.connected
    enabled: page.canEdit
    opacity: enabled ? 1 : 0.5
    width: parent.width
    Item {
      width: parent.width
      height: 26
      Icon { id: dpiIc; anchors.verticalCenter: parent.verticalCenter; name: "speed"; color: Theme.textDim }
      Text { anchors.left: dpiIc.right; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: "DPI"; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
      Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: String(page.s.dpi || "—"); color: Theme.accent; font.family: Theme.fontDisplay; font.pixelSize: 18; font.weight: Font.Bold }
    }
    Chips {
      model: page.stages.map(String)
      current: page.activeStage - 1
      onPicked: (i) => page.send(["set", "active-stage", String(i + 1)])
    }
    SliderRow {
      icon: "tune"
      value: ((page.s.dpi || 800) - 50) / (26000 - 50)
      onMoved: (v) => page.send(["set", "dpi-stage", String(page.activeStage), String(Math.round((50 + v * (26000 - 50)) / 50) * 50)])
    }
    Text { text: "Polling rate (Hz)"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
    Chips {
      model: page.polling.map(p => p[1])
      current: page.polling.findIndex(p => p[0] === String(page.s.pollingHz || ""))
      onPicked: (i) => page.send(["set", "polling", page.polling[i][0]])
    }
  }

  // Lighting
  Card {
    visible: page.connected
    enabled: page.canEdit
    opacity: enabled ? 1 : 0.5
    width: parent.width
    Item {
      width: parent.width
      height: 24
      Icon { id: lIc; anchors.verticalCenter: parent.verticalCenter; name: "light_mode"; color: Theme.textDim }
      Text { anchors.left: lIc.right; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: "Lighting"; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
    }
    Chips {
      model: page.effects.map(e => e.label)
      current: page.effects.findIndex(e => e.value === page.effect)
      onPicked: (i) => page.send(["light", "effect", page.effects[i].value])
    }
    SliderRow {
      icon: "brightness_6"
      enabled: page.canEdit && page.effect !== "off"
      value: ((page.light.brightness || 1) - 1) / 9
      text: String(page.light.brightness || 1)
      onMoved: (v) => page.send(["light", "brightness", String(1 + Math.round(v * 9))])
    }
    SliderRow {
      visible: page.effect !== "off" && page.effect !== "fixed-color" && page.effect !== "fixed-rainbow"
      icon: "fast_forward"
      value: ((page.light.speed || 1) - 1) / 9
      text: String(page.light.speed || 1)
      onMoved: (v) => page.send(["light", "speed", String(1 + Math.round(v * 9))])
    }
    Swatches {
      visible: page.effect === "fixed-color" || page.effect === "single-color-breath"
      colours: page.colours
      current: page.light.color || ""
      onPicked: (c) => page.send(["light", "color", c])
    }
    SwitchRow {
      icon: "motion_photos_off"; label: "Off while moving"
      checked: !!page.light.offWhenMoving
      onToggled: (v) => page.send(["light", "off-when-moving", page.onOff(v)])
    }
  }

  // Buttons and macros live in OmaGravastar's big window.
  Row {
    anchors.right: parent.right
    visible: !!(page.hosted && page.hosted.panel)
    spacing: 8
    RoundButton { icon: "smart_button"; onClicked: { page.closeRequested(); page.hosted.openPanel(page.hosted.pluginId, JSON.stringify({ view: "buttons", button: 1 })) } }
    RoundButton { icon: "keyboard_command_key"; onClicked: { page.closeRequested(); page.hosted.openPanel(page.hosted.pluginId, JSON.stringify({ view: "macros" })) } }
  }
}
