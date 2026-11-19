import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../"

// MonitorPills — one pill per monitor, laid out like the desk (left to right,
// main row first, the one above after). The pill for the monitor the mouse is
// on is big and lit. Each pill holds dots for that monitor's workspaces:
// click a dot to go there. Hover a pill to peek at its window (Hover.qml shows
// the picture); drag a pill onto another pill to move that window there.
Item {
  id: root

  property bool active: false          // the hover card is showing: keep window info fresh
  property string hovered: ""          // monitor whose pill the mouse is on (lingers a moment)
  property string dragFrom: ""         // monitor whose window is being dragged
  property string dropOn: ""           // pill under the dragged window
  property point dragPos: Qt.point(0, 0)
  readonly property string peekMonitor: dragFrom || hovered

  implicitWidth: row.implicitWidth
  implicitHeight: 18

  readonly property var monitors: Hyprland.monitors.values.slice().sort((a, b) =>
    a.x !== b.x ? a.x - b.x : Math.abs(a.y) - Math.abs(b.y))

  // ── Fresh window info while showing ───────────
  property int rev: 0
  function refresh() { Hyprland.refreshMonitors(); Hyprland.refreshToplevels(); bump.restart() }
  Timer { id: bump; interval: 120; onTriggered: root.rev++ }
  onActiveChanged: if (active) refresh(); else { hovered = ""; dragFrom = ""; dropOn = "" }
  Connections {
    target: Hyprland
    enabled: root.active
    function onRawEvent(ev) {
      if (/^(activewindow|movewindow|openwindow|closewindow|workspace|focusedmon|activespecial)/.test(ev.name)) settle.restart()
    }
  }
  Timer { id: settle; interval: 80; onTriggered: root.refresh() }

  function monitor(name) { return Hyprland.monitors.values.find(m => m.name === name) || null }
  // The workspace you see on a monitor (an open special workspace counts).
  function shownWorkspace(m, includeSpecial) {
    const ipc = m.lastIpcObject || {}
    if (includeSpecial && ipc.specialWorkspace && ipc.specialWorkspace.id) return ipc.specialWorkspace.id
    return ipc.activeWorkspace ? ipc.activeWorkspace.id : (m.activeWorkspace ? m.activeWorkspace.id : 0)
  }
  // The window you'd be looking at on that monitor: the most recently focused
  // one on the workspace showing there.
  function windowOn(name) {
    void(rev)
    const m = monitor(name)
    if (!m) return null
    const ws = shownWorkspace(m, true)
    let best = null, bestH = 1e9
    for (const t of Hyprland.toplevels.values) {
      const o = t.lastIpcObject || {}
      const wid = o.workspace ? o.workspace.id : (t.workspace ? t.workspace.id : null)
      if (wid !== ws) continue
      const h = o.focusHistoryID !== undefined ? o.focusHistoryID : 1e8
      if (h < bestH) { bestH = h; best = t }
    }
    return best
  }
  function addressOf(t) {
    const o = t.lastIpcObject || {}
    return o.address || ("0x" + String(t.address).replace(/^0x/, ""))
  }
  // Drop: the window goes to the regular workspace showing on the other
  // monitor (never into a special/scratchpad one), and focus stays put.
  function moveWindow(from, to) {
    const t = windowOn(from), m = monitor(to)
    if (!t || !m) return
    const ws = shownWorkspace(m, false)
    if (!ws) return
    Quickshell.execDetached(["hyprctl", "dispatch",
      'hl.dsp.window.move({ workspace = "' + ws + '", follow = false, window = "address:' + addressOf(t) + '" })'])
    settle.restart()
  }
  function pillAt(x, y) {
    if (y < -24 || y > root.height + 24) return ""
    const c = row.childAt(x - row.x, row.height / 2)
    return c && c.monitorName ? c.monitorName : ""
  }

  // Moving between pills shouldn't close the peek for a blink.
  Timer { id: unhover; interval: 300; onTriggered: root.hovered = "" }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 8

    Repeater {
      model: root.monitors

      Rectangle {
        id: pill
        required property var modelData
        readonly property string monitorName: modelData.name
        readonly property bool here: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === monitorName
        readonly property bool target: root.dragFrom !== "" && root.dragFrom !== monitorName && root.dropOn === monitorName
        readonly property bool source: root.dragFrom === monitorName
        readonly property var spaces: Hyprland.workspaces.values
          .filter(w => w.id > 0 && w.monitor && w.monitor.name === pill.monitorName)
          .sort((a, b) => a.id - b.id)

        anchors.verticalCenter: parent.verticalCenter
        height: here ? 18 : 12
        width: dots.implicitWidth + (here ? 18 : 12)
        radius: height / 2
        color: here ? Theme.accent : Theme.surfaceRaised
        border.width: target || (root.hovered === monitorName && !here) ? 2 : 0
        border.color: Theme.accent
        opacity: source ? 0.5 : 1
        scale: target ? 1.15 : 1
        Behavior on width { NumberAnimation { duration: Motion.ms(Motion.hover * 2); easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Motion.ms(Motion.hover * 2); easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
        Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.hover); easing.type: Easing.OutBack } }

        Row {
          id: dots
          anchors.centerIn: parent
          spacing: 4
          Repeater {
            model: pill.spaces
            Rectangle {
              required property var modelData
              readonly property var ws: modelData
              readonly property bool on: pill.modelData.activeWorkspace !== null && pill.modelData.activeWorkspace.id === modelData.id
              anchors.verticalCenter: parent.verticalCenter
              width: on ? (pill.here ? 14 : 9) : 5
              height: pill.here ? 6 : 5
              radius: height / 2
              color: pill.here ? (on ? Theme.surface : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45))
                               : (on ? Theme.text : Theme.textDim)
              Behavior on width { NumberAnimation { duration: Motion.ms(Motion.hover * 2); easing.type: Easing.OutCubic } }
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          anchors.margins: -4
          hoverEnabled: true
          preventStealing: true
          cursorShape: root.dragFrom !== "" ? Qt.ClosedHandCursor : Qt.PointingHandCursor
          property point start
          property bool dragged: false
          onEntered: { unhover.stop(); root.hovered = pill.monitorName }
          onExited: unhover.restart()
          onPressed: (m) => { start = Qt.point(m.x, m.y); dragged = false }
          onPositionChanged: (m) => {
            if (!pressed) return
            if (!dragged && Math.hypot(m.x - start.x, m.y - start.y) > 6 && root.windowOn(pill.monitorName)) {
              dragged = true
              root.dragFrom = pill.monitorName
            }
            if (dragged) {
              root.dragPos = mapToItem(root, m.x, m.y)
              root.dropOn = root.pillAt(root.dragPos.x, root.dragPos.y)
            }
          }
          onReleased: {
            if (dragged && root.dropOn && root.dropOn !== root.dragFrom) root.moveWindow(root.dragFrom, root.dropOn)
            root.dragFrom = ""; root.dropOn = ""
          }
          // A click (no drag) on a dot goes to that workspace.
          onClicked: (m) => {
            if (dragged) return
            const p = mapToItem(dots, m.x, m.y)
            const d = dots.childAt(p.x, dots.height / 2)
            if (d && d.ws) d.ws.activate()
          }
        }
      }
    }
  }

  // The window you're carrying.
  Rectangle {
    visible: root.dragFrom !== ""
    x: root.dragPos.x - width / 2
    y: root.dragPos.y - height - 6
    width: ghostText.implicitWidth + 20
    height: 22
    radius: 11
    color: Theme.accent
    z: 10
    Text {
      id: ghostText
      anchors.centerIn: parent
      readonly property var w: root.dragFrom ? root.windowOn(root.dragFrom) : null
      text: w ? (w.lastIpcObject && w.lastIpcObject.class ? w.lastIpcObject.class : w.title) : ""
      color: Theme.surface; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold
    }
  }
}
