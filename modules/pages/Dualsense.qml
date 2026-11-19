import QtQuick
import "../../"

// DualSense — your PlayStation controller as a DankShell page: lightbar,
// player lights, adaptive triggers, rumble, the built-in mic and speaker, a
// live input tester and the controller's details. Changes go through the
// DualSense plugin's own helper (services/DualSense.qml); the controller
// picture and tester are the plugin's own (MIT).
Column {
  id: page
  property bool showing: false
  spacing: 10

  onShowingChanged: { DualSense.watching = showing; if (!showing) DualSense.testing = false }
  Component.onDestruction: { DualSense.watching = false; DualSense.testing = false }

  property string tab: "lights"
  property bool linked: true    // same effect on both triggers
  readonly property var tabs: [["lights", "Lights"], ["feel", "Feel"], ["audio", "Audio"], ["test", "Test"], ["info", "Info"]]
  readonly property var swatches: ["#1e64ff", "#00e0ff", "#20ff50", "#ffd000", "#ff7a00", "#ff2020", "#ff40b0", "#a020ff", "#ffffff"]
  readonly property var effects: [["off", "Off"], ["feedback", "Resistance"], ["weapon", "Weapon"], ["bow", "Bow"], ["galloping", "Galloping"], ["machine", "Machine"], ["vibration", "Vibration"]]

  function hueOf(hex) { const c = Qt.color(hex); return c.hsvHue < 0 ? 0 : c.hsvHue }
  function hexFromHue(h) { return String(Qt.hsva(h, 1, 1, 1)).substring(0, 7) }
  readonly property color barColor: {
    const c = Qt.color(DualSense.lightbarHex), b = Math.max(0, Math.min(100, Number(DualSense.lightbar.brightness))) / 100
    return Qt.rgba(c.r * b, c.g * b, c.b * b, 1)
  }

  // ── Who's connected ───────────────────────────
  Card {
    width: parent.width
    DeviceHeader {
      icon: "sports_esports"
      title: DualSense.connected ? String(DualSense.device.model) : "DualSense"
      subtitle: !DualSense.connected ? "Not connected · USB or Bluetooth"
        : [DualSense.bluetooth ? "Bluetooth" : "USB", DualSense.capacity >= 0 ? DualSense.capacity + "%" : "",
           DualSense.full ? "Full" : DualSense.charging ? "Charging" : "On battery"].filter(s => s).join(" · ")
      active: DualSense.connected
      trailingIcon: !DualSense.connected || DualSense.capacity < 0 ? "" : DualSense.charging ? "battery_charging_full"
                  : DualSense.capacity <= 20 ? "battery_alert" : DualSense.capacity <= 60 ? "battery_4_bar" : "battery_full"
      trailingColor: DualSense.capacity >= 0 && DualSense.capacity <= 20 && !DualSense.charging ? Theme.urgent : Theme.accent
    }
    // The plugin's own drawing of the controller, lit like yours.
    Loader {
      visible: DualSense.connected && status === Loader.Ready
      width: Math.min(parent.width, 300)
      anchors.horizontalCenter: parent.horizontalCenter
      source: "file://" + DualSense.pluginDir + "DualSenseShape.qml"
      onLoaded: {
        item.width = Qt.binding(() => width)
        item.lightbarColor = Qt.binding(() => Qt.lighter(page.barColor, 1.15))
        item.lightbarOn = Qt.binding(() => DualSense.lightbar.enabled !== false)
        item.micMuted = Qt.binding(() => DualSense.audio.micMuted === true)
        item.ledPattern = Qt.binding(() => DualSense.ledPattern)
        item.accent = Qt.binding(() => Theme.accent)
        item.foreground = Qt.binding(() => Theme.text)
      }
    }
    Chips {
      visible: DualSense.connected
      model: page.tabs.map(t => t[1])
      current: page.tabs.findIndex(t => t[0] === page.tab)
      onPicked: (i) => page.tab = page.tabs[i][0]
    }
    Text {
      visible: DualSense.connected && !DualSense.canControl
      width: parent.width; wrapMode: Text.WordWrap
      text: "Lights and triggers need access to the controller (hidraw). The DualSense plugin's udev rule gives it."
      color: Theme.urgent; font.family: Theme.fontText; font.pixelSize: 11
    }
  }

  // Not connected
  Card {
    visible: !DualSense.connected
    width: parent.width
    Text { width: parent.width; wrapMode: Text.WordWrap; text: "Turn the controller on (PS button) or plug it in."; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12 }
    Row { spacing: 8; RoundButton { icon: "bluetooth_searching"; onClicked: DualSense.reconnect() } RoundButton { icon: "refresh"; onClicked: DualSense.refresh() } }
  }

  // ── Lights ────────────────────────────────────
  Card {
    visible: DualSense.connected && page.tab === "lights"
    width: parent.width
    enabled: DualSense.canControl
    SwitchRow { icon: "lightbulb"; label: "Lightbar"; checked: DualSense.lightbar.enabled !== false; onToggled: (v) => DualSense.set("lightbar.enabled", v) }
    SwitchRow { icon: "palette"; label: "Follow theme accent"; sub: "The lightbar takes your theme's color"; checked: DualSense.lightbar.followTheme === true; onToggled: (v) => DualSense.set("lightbar.followTheme", v) }
    Swatches {
      colours: page.swatches
      current: DualSense.lightbar.followTheme ? "" : DualSense.lightbar.color
      onPicked: (c) => DualSense.setColor(c)
    }
    SliderRow {
      icon: "colorize"; live: true
      enabled: DualSense.lightbar.followTheme !== true
      value: page.hueOf(DualSense.lightbarHex)
      text: DualSense.lightbarHex.toUpperCase()
      onMoved: (v) => DualSense.preview(page.hexFromHue(v), DualSense.lightbar.brightness)
      onReleased: (v) => DualSense.setColor(page.hexFromHue(v))
    }
    SliderRow {
      icon: "brightness_6"; live: true
      value: Number(DualSense.lightbar.brightness) / 100
      text: Math.round(DualSense.lightbar.brightness) + "%"
      onMoved: (v) => DualSense.preview(DualSense.lightbarHex, v * 100)
      onReleased: (v) => DualSense.set("lightbar.brightness", Math.round(v * 100))
    }
    Text { text: "Player lights"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }
    Chips { model: ["Off", "1", "2", "3", "4", "5"]; current: Math.min(5, Number(DualSense.player.leds)); onPicked: (i) => DualSense.set("player.leds", i) }
    Chips { model: ["High", "Medium", "Low"]; current: ["high", "medium", "low"].indexOf(String(DualSense.player.brightness)); onPicked: (i) => DualSense.set("player.brightness", ["high", "medium", "low"][i]) }
  }

  // ── Feel ──────────────────────────────────────
  Card {
    visible: DualSense.connected && page.tab === "feel"
    width: parent.width
    enabled: DualSense.canControl
    SwitchRow { icon: "link"; label: "Same effect on both triggers"; sub: "Off lets L2 and R2 differ"; checked: page.linked; onToggled: (v) => page.linked = v }
    Text { text: page.linked ? "Triggers" : "L2"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }
    Chips {
      model: page.effects.map(e => e[1])
      current: page.effects.findIndex(e => e[0] === String(DualSense.triggers.left.effect))
      onPicked: (i) => { if (page.linked) DualSense.setTriggers(page.effects[i][0]); else DualSense.set("triggers.left.effect", page.effects[i][0]) }
    }
    Text { visible: !page.linked; text: "R2"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold }
    Chips {
      visible: !page.linked
      model: page.effects.map(e => e[1])
      current: page.effects.findIndex(e => e[0] === String(DualSense.triggers.right.effect))
      onPicked: (i) => DualSense.set("triggers.right.effect", page.effects[i][0])
    }
    SliderRow {
      icon: "fitness_center"
      value: (Number(DualSense.triggers.left.strength) - 1) / 7
      text: DualSense.triggers.left.strength + " / 8"
      onMoved: (v) => DualSense.setStrength(1 + Math.round(v * 7))
    }
  }
  Card {
    visible: DualSense.connected && page.tab === "feel"
    width: parent.width
    Text { text: "Motors"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }
    SliderRow {
      icon: "vibration"
      value: (8 - Number(DualSense.motors.rumble) - 1) / 7
      text: (8 - Number(DualSense.motors.rumble)) + " / 8"
      onMoved: (v) => DualSense.set("motors.rumble", 8 - (1 + Math.round(v * 7)))
    }
    SliderRow {
      icon: "gamepad"
      value: (8 - Number(DualSense.motors.trigger) - 1) / 7
      text: (8 - Number(DualSense.motors.trigger)) + " / 8"
      onMoved: (v) => DualSense.set("motors.trigger", 8 - (1 + Math.round(v * 7)))
    }
    Row { spacing: 8; RoundButton { icon: "vibration"; onClicked: DualSense.rumble() } Text { anchors.verticalCenter: parent.verticalCenter; text: "Test rumble (half a second)"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11 } }
  }

  // ── Audio ─────────────────────────────────────
  Card {
    visible: DualSense.connected && page.tab === "audio"
    width: parent.width
    enabled: DualSense.canControl
    SwitchRow { icon: DualSense.audio.micMuted ? "mic_off" : "mic"; label: "Mute microphone"; sub: DualSense.audio.micMuted ? "The built-in mic is muted" : "The built-in mic is live"; checked: DualSense.audio.micMuted === true; onToggled: (v) => DualSense.set("audio.micMuted", v) }
    Text { text: "Mic light"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }
    Chips { model: ["Auto", "Off", "On", "Pulse"]; current: ["auto", "off", "on", "pulse"].indexOf(String(DualSense.audio.micLed)); onPicked: (i) => DualSense.set("audio.micLed", ["auto", "off", "on", "pulse"][i]) }
    SliderRow {
      icon: "mic"
      value: (DualSense.audio.micVolume === null || DualSense.audio.micVolume === undefined ? 100 : Number(DualSense.audio.micVolume)) / 100
      text: DualSense.audio.micVolume === null || DualSense.audio.micVolume === undefined ? "default" : DualSense.audio.micVolume + "%"
      onMoved: (v) => DualSense.set("audio.micVolume", Math.round(v * 100))
    }
    Text { text: "Sound out of"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }
    Chips {
      readonly property var vals: ["", "headphone", "internal", "both"]
      model: ["Default", "Headphones", "Speaker", "Both"]
      current: vals.indexOf(DualSense.audio.speaker === null || DualSense.audio.speaker === undefined ? "" : String(DualSense.audio.speaker))
      onPicked: (i) => DualSense.set("audio.speaker", vals[i] === "" ? null : vals[i])
    }
    SliderRow {
      icon: "volume_up"
      value: (DualSense.audio.volume === null || DualSense.audio.volume === undefined ? 70 : Number(DualSense.audio.volume)) / 100
      text: DualSense.audio.volume === null || DualSense.audio.volume === undefined ? "default" : DualSense.audio.volume + "%"
      onMoved: (v) => DualSense.set("audio.volume", Math.round(v * 100))
    }
  }

  // ── Test ──────────────────────────────────────
  Card {
    visible: DualSense.connected && page.tab === "test"
    width: parent.width
    SwitchRow { icon: "joystick"; label: "Live input"; sub: DualSense.testing ? "Press anything on the controller" : "Sticks, triggers, buttons, touchpad and motion"; checked: DualSense.testing; onToggled: (v) => DualSense.testing = v }
    Loader {
      active: DualSense.testing
      visible: active
      width: parent.width
      source: "file://" + DualSense.pluginDir + "GamepadTester.qml"
      onLoaded: {
        item.width = Qt.binding(() => width)
        item.live = Qt.binding(() => DualSense.live)
        item.lightbarColor = Qt.binding(() => page.barColor)
        item.lightbarOn = Qt.binding(() => DualSense.lightbar.enabled !== false)
        item.micMuted = Qt.binding(() => DualSense.audio.micMuted === true)
        item.ledPattern = Qt.binding(() => DualSense.ledPattern)
        item.accent = Qt.binding(() => Theme.accent)
        item.foreground = Qt.binding(() => Theme.text)
        item.fontFamily = Theme.fontText
      }
    }
  }

  // ── Info ──────────────────────────────────────
  Card {
    visible: DualSense.connected && page.tab === "info"
    width: parent.width
    Repeater {
      model: !DualSense.connected ? [] : [
        ["Connection", DualSense.bluetooth ? "Bluetooth" : "USB"],
        ["Address", String(DualSense.device.mac || "").toUpperCase()],
        ["Firmware", DualSense.device.firmware ? DualSense.device.firmware.version + " · " + DualSense.device.firmware.buildDate : String(DualSense.device.firmwareVersion || "")],
        ["Hardware", String(DualSense.device.hardwareVersion || "")],
        ["Driver", String(DualSense.device.driver || "")]
      ]
      Item {
        required property var modelData
        width: parent.width; height: 22
        Text { text: modelData[0]; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11 }
        Text { anchors.right: parent.right; text: modelData[1]; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11 }
      }
    }
    Row {
      spacing: 8
      RoundButton { icon: "replay"; onClicked: DualSense.reapply() }
      RoundButton { icon: "restart_alt"; onClicked: DualSense.reset() }
      RoundButton { visible: DualSense.bluetooth; icon: "power_settings_new"; onClicked: DualSense.powerOff() }
    }
    Text { text: "Reapply profile · Reset to defaults" + (DualSense.bluetooth ? " · Turn off" : ""); color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
  }
}
