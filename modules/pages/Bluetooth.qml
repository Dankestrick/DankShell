import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../"

// Bluetooth — its own window (right-click Home's Bluetooth tile).
// While it's open it looks for new devices; click one to pair and connect it.
// Paired devices connect with a click, and × forgets one.
// The pairing itself is Omarchy's own helper (omarchy-bluetooth-device), the
// same one its Bluetooth dropdown uses. A headset that connects becomes your
// sound output, like Omarchy does.
Column {
  id: page
  property bool showing: false
  spacing: 10

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool on: !!adapter && adapter.enabled
  readonly property bool scanning: on && adapter.discovering

  // ── The device lists ──────────────────────────
  // Plain values only (no live BlueZ objects in the rows): a device can vanish
  // mid-scan, and holding it in a row can crash the shell. Actions look the
  // device up again by its address.
  readonly property var all: Bluetooth.devices ? Bluetooth.devices.values : []
  function label(d) { return String(d.deviceName || d.name || "").trim() }
  function human(d) {
    const t = label(d)
    return t !== "" && !/^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i.test(t) && !/^[0-9a-f-]{32,36}$/i.test(t)
  }
  function row(d) {
    return { address: d.address || "", name: label(d), icon: String(d.icon || ""), connected: !!d.connected,
             battery: d.batteryAvailable ? Math.round(d.battery * 100) : -1 }
  }
  readonly property var lists: {
    const c = [], k = [], f = []
    for (const d of all) {
      if (!d || !human(d)) continue
      if (d.connected) c.push(row(d))
      else if (d.paired || d.bonded || d.trusted) k.push(row(d))
      else f.push(row(d))
    }
    const byName = (a, b) => a.name.localeCompare(b.name)
    return { connected: c.sort(byName), known: k.sort(byName), found: f.sort(byName) }
  }
  function deviceFor(address) { return all.find(d => d && d.address === address) || null }

  // ── Doing things ──────────────────────────────
  // address → "Pairing…" / "Connecting…" / "Disconnecting…" / "Forgetting…"
  property var pending: ({})
  function setPending(address, text) {
    const p = Object.assign({}, pending)
    if (text) p[address] = text; else delete p[address]
    pending = p
    if (text) pendingTimeout.restart()
  }
  function act(r, action, text) {
    setPending(r.address, text)
    Quickshell.execDetached(["omarchy-bluetooth-device", action, r.address])
  }
  function connectOrPair(r, isNew) { act(r, isNew ? "pair" : "connect", isNew ? "Pairing…" : "Connecting…") }
  function disconnect(r) { act(r, "disconnect", "Disconnecting…") }
  function forget(r) { act(r, "forget", "Forgetting…") }

  // Clear "Connecting…" once it's really connected (and switch the sound to it).
  onListsChanged: sync()
  function sync() {
    let changed = false
    const p = Object.assign({}, pending)
    for (const a in p) {
      const d = deviceFor(a)
      const done = (p[a] === "Pairing…" || p[a] === "Connecting…") ? (d && d.connected)
                 : p[a] === "Disconnecting…" ? (d && !d.connected)
                 : (!d || !(d.paired || d.bonded || d.trusted))
      if (done) {
        if (d && d.connected) { soundTo = a; soundTries = 0; soundTimer.restart() }
        delete p[a]; changed = true
      }
    }
    if (changed) pending = p
  }
  Timer { id: pendingTimeout; interval: 30000; onTriggered: page.pending = ({}) }

  // A headset that just connected: make it the output once its sink shows up.
  property string soundTo: ""
  property int soundTries: 0
  Timer {
    id: soundTimer
    interval: 750
    onTriggered: {
      const key = page.soundTo.toLowerCase().replace(/[^0-9a-f]/g, "")
      const out = Sound.outputs.find(o => o.name.toLowerCase().replace(/[^0-9a-f]/g, "").indexOf(key) >= 0
                                         && o.name.indexOf("bluez") === 0)
      if (out) { if (!out.on) Sound.useOutput(out); page.soundTo = ""; return }
      if (++page.soundTries < 8) restart(); else page.soundTo = ""
    }
  }

  // ── Looking for devices ───────────────────────
  // Scan while the window is open; BlueZ can refuse or time out, so keep
  // nudging it. Stop when it closes, or the radio stays busy scanning and
  // Bluetooth audio stutters.
  property bool owesStop: false
  Timer {
    interval: 1000; repeat: true; triggeredOnStart: true
    running: page.showing && page.on && !page.adapter.discovering
    onTriggered: { page.owesStop = true; page.adapter.discovering = true }
  }
  Timer {
    id: stopTimer
    interval: 1000; repeat: true
    property int tries: 0
    running: !page.showing && page.owesStop && !!page.adapter && page.adapter.discovering
    onRunningChanged: if (running) tries = 0
    onTriggered: { if (++tries > 3) { page.owesStop = false; return } page.adapter.discovering = false }
  }
  Connections {
    target: page.adapter
    function onDiscoveringChanged() { if (!page.adapter.discovering) page.owesStop = false }
  }
  Component.onDestruction: if (owesStop && adapter && adapter.discovering) adapter.discovering = false

  // ── On/off ────────────────────────────────────
  Card {
    width: parent.width
    SwitchRow {
      icon: "bluetooth"
      label: "Bluetooth"
      sub: !page.on ? "Off" : page.scanning ? "On · looking for devices nearby" : "On"
      checked: page.on
      onToggled: Toggles.toggleBluetooth()
    }
  }

  component Head: Text {
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
    font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase; leftPadding: 4
  }
  function iconOf(r) {
    const i = r.icon
    return i.includes("headset") || i.includes("headphone") || i.includes("audio") ? "headphones"
         : i.includes("gam") ? "sports_esports"
         : i.includes("phone") ? "smartphone"
         : i.includes("mouse") ? "mouse"
         : i.includes("keyboard") ? "keyboard"
         : "bluetooth"
  }
  // One device: click the row to connect/disconnect/pair; × forgets a paired one.
  component BtRow: Rectangle {
    id: br
    property var r: ({})
    property bool isNew: false
    readonly property string busy: page.pending[r.address] || ""
    width: parent ? parent.width : 300
    height: 40; radius: 12
    color: r.connected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
         : brTap.containsMouse ? Theme.surface : "transparent"
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Icon { id: bi; x: 10; anchors.verticalCenter: parent.verticalCenter; name: page.iconOf(br.r); filled: br.r.connected; color: br.r.connected ? Theme.accent : Theme.textDim }
    Text {
      anchors.left: bi.right; anchors.leftMargin: 10; anchors.right: bs.left; anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
      text: br.r.name; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12
      font.weight: br.r.connected ? Font.DemiBold : Font.Normal
    }
    Text {
      id: bs
      anchors.right: x.visible ? x.left : parent.right; anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: br.busy !== "" ? br.busy
          : br.r.connected ? (br.r.battery >= 0 ? br.r.battery + "%  ·  Connected" : "Connected")
          : br.isNew ? "Click to pair" : "Click to connect"
      color: br.busy !== "" || br.r.connected ? Theme.accent : Theme.textDim
      font.family: Theme.fontText; font.pixelSize: 10
    }
    MouseArea {
      id: brTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
      enabled: br.busy === ""
      onClicked: br.r.connected ? page.disconnect(br.r) : page.connectOrPair(br.r, br.isNew)
    }
    Rectangle {
      id: x
      visible: !br.isNew && br.busy === ""
      anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
      width: 28; height: 28; radius: 14
      color: xTap.containsMouse ? Theme.surfaceRaised : "transparent"
      Icon { anchors.centerIn: parent; name: "close"; font.pixelSize: 15; color: xTap.containsMouse ? Theme.urgent : Theme.textDim }
      MouseArea { id: xTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.forget(br.r) }
    }
  }

  // ── Connected + paired ────────────────────────
  Card {
    width: parent.width
    visible: page.on
    spacing: 4
    Head { text: "My devices" }
    Repeater { model: page.lists.connected; BtRow { required property var modelData; r: modelData } }
    Repeater { model: page.lists.known; BtRow { required property var modelData; r: modelData } }
    Text {
      visible: page.lists.connected.length + page.lists.known.length === 0
      text: "Nothing paired yet"; leftPadding: 10
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
    }
  }

  // ── New devices nearby ────────────────────────
  Card {
    width: parent.width
    visible: page.on
    spacing: 4
    Head { text: page.scanning ? "Nearby · looking…" : "Nearby" }
    Text {
      width: parent.width; wrapMode: Text.WordWrap; leftPadding: 4
      text: "Put the device in pairing mode, then click it here. Shokz: with the headphones off, hold + until the light flashes red and blue."
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
    }
    Repeater { model: page.lists.found; BtRow { required property var modelData; r: modelData; isNew: true } }
    Text {
      visible: page.lists.found.length === 0
      text: page.scanning ? "Looking…" : "Nothing new found"; leftPadding: 10
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
    }
  }

  Text {
    visible: !page.on
    text: "Turn Bluetooth on to find your devices."
    leftPadding: 10
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
  }
}
