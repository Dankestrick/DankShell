import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../"
import "../config/Docker.js" as Spaces

// MonitorPills — one pill per monitor, laid out like the desk (left to right,
// main row first, the one above after). The pill for the monitor the mouse is
// on is big and lit. Each pill holds dots for that monitor's workspaces:
// click a dot to go there. Hover a pill to peek at its window (Hover.qml shows
// the picture); drag a pill onto another pill to move that window there, or
// drag a dot to carry a window off that workspace without going there.
// While you drag over a pill it spreads out into that monitor's workspaces
// (1 · 4 · 7 on the main) so you can drop the window on the one you want.
Item {
  id: root

  property bool active: false          // the hover card is showing: keep window info fresh
  property string hovered: ""          // monitor whose pill the mouse is on (lingers a moment)
  property string dragFrom: ""         // monitor whose window is being dragged
  property string dropOn: ""           // pill under the dragged window
  property int dropWs: 0               // workspace slot under it (0 = the one showing)
  property int dragWs: 0               // dragged off a workspace's dot: that workspace (0 = the one showing)
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
  onActiveChanged: if (active) refresh(); else { hovered = ""; dragFrom = ""; dropOn = ""; dropWs = 0; dragWs = 0 }
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
  // The workspace a pill stands for right now: the one showing there, or the
  // one whose dot you're dragging a window off.
  function sourceWorkspace(name, m) {
    return name === dragFrom && dragWs ? dragWs : shownWorkspace(m, true)
  }
  // The window you'd be looking at on that monitor: the most recently focused
  // one on that workspace.
  function windowOn(name) {
    void(rev)
    const m = monitor(name)
    if (!m) return null
    const ws = sourceWorkspace(name, m)
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
  // Every window on the workspace showing there, left to right (the peek shows them all).
  function windowsOn(name) {
    void(rev)
    const m = monitor(name)
    if (!m) return []
    const ws = sourceWorkspace(name, m)
    return Hyprland.toplevels.values.filter(t => {
      const o = t.lastIpcObject || {}
      const wid = o.workspace ? o.workspace.id : (t.workspace ? t.workspace.id : null)
      return wid === ws && !o.hidden
    }).sort((a, b) => {
      const pa = (a.lastIpcObject || {}).at || [0, 0], pb = (b.lastIpcObject || {}).at || [0, 0]
      return pa[0] !== pb[0] ? pa[0] - pb[0] : pa[1] - pb[1]
    })
  }
  // The peek keeps itself open while the mouse is on it (Hover.qml sets this).
  property bool peekHeld: false
  onPeekHeldChanged: if (peekHeld) unhover.stop(); else if (!pillHover) unhover.restart()
  property bool pillHover: false
  function addressOf(t) {
    const o = t.lastIpcObject || {}
    return o.address || ("0x" + String(t.address).replace(/^0x/, ""))
  }
  // Drop: the window goes to the regular workspace showing on the other
  // monitor (never into a special/scratchpad one), and focus stays put.
  function moveWindow(from, to, wsPicked) {
    const t = windowOn(from), m = monitor(to)
    if (!t || !m) return
    const ws = wsPicked || shownWorkspace(m, false)
    if (!ws || (from === to && ws === sourceWorkspace(from, monitor(from)))) return
    Quickshell.execDetached(["hyprctl", "dispatch",
      'hl.dsp.window.move({ workspace = "' + ws + '", follow = false, window = "address:' + addressOf(t) + '" })'])
    settle.restart()
  }
  function pillAt(x, y) {
    if (y < -24 || y > root.height + 24) return ""
    const c = row.childAt(x - row.x, row.height / 2)
    return c && c.monitorName ? c.monitorName : ""
  }
  // The workspace slot under x on a spread-out pill.
  function slotAt(x) {
    const c = row.childAt(x - row.x, row.height / 2)
    if (!c || !c.slotRow) return 0
    const p = root.mapToItem(c.slotRow, x, 0)
    const s = c.slotRow.childAt(p.x, c.slotRow.height / 2)
    return s && s.wsId ? s.wsId : 0
  }
  // The dot nearest x on a pill's dot row (they're tiny, so a few px either side counts).
  function dotNear(dotRow, x) {
    let best = null, bestD = 7
    for (let i = 0; i < dotRow.children.length; i++) {
      const d = dotRow.children[i]
      if (!d.ws) continue
      const dist = Math.abs(d.x + d.width / 2 - x)
      if (dist < bestD) { bestD = dist; best = d }
    }
    return best
  }

  // Moving between pills shouldn't close the peek for a blink.
  Timer { id: unhover; interval: 350; onTriggered: if (!root.peekHeld && !root.pillHover) root.hovered = "" }
  property string pending: ""   // the pill the mouse went onto last

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
        readonly property bool target: root.dragFrom !== "" && root.dropOn === monitorName
        readonly property var plan: Spaces.SPACES[monitorName] || []
        readonly property alias slotRow: slots
        readonly property bool source: root.dragFrom === monitorName
        readonly property var spaces: Hyprland.workspaces.values
          .filter(w => w.id > 0 && w.monitor && w.monitor.name === pill.monitorName)
          .sort((a, b) => a.id - b.id)

        anchors.verticalCenter: parent.verticalCenter
        height: target ? 22 : here ? 18 : 12
        width: (target ? slots.implicitWidth : dots.implicitWidth) + (target ? 10 : here ? 18 : 12)
        radius: height / 2
        color: here ? Theme.accent : Theme.surfaceRaised
        border.width: target || (root.hovered === monitorName && !here) ? 2 : 0
        border.color: Theme.accent
        opacity: source && !target ? 0.5 : 1
        Behavior on width { NumberAnimation { duration: Motion.ms(Motion.hover * 2); easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Motion.ms(Motion.hover * 2); easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
        Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.hover); easing.type: Easing.OutBack } }

        // While dragging over it: one numbered slot per workspace of this monitor.
        Row {
          id: slots
          anchors.centerIn: parent
          spacing: 3
          visible: pill.target
          Repeater {
            model: pill.target ? pill.plan : []
            Rectangle {
              required property var modelData
              readonly property int wsId: modelData
              readonly property bool under: root.dropWs === modelData
              readonly property bool showing: pill.modelData.activeWorkspace !== null && pill.modelData.activeWorkspace.id === modelData
              width: 22; height: 16; radius: 8
              color: under ? Theme.text : showing ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25) : "transparent"
              Text {
                anchors.centerIn: parent
                text: modelData
                color: parent.under ? Theme.surface : pill.here ? Theme.surface : Theme.text
                font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold
              }
            }
          }
        }

        Row {
          id: dots
          visible: !pill.target
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
          // A big target around the small pill: half the gap on each side, 10px above and below.
          anchors.fill: parent
          anchors.leftMargin: -4; anchors.rightMargin: -4
          anchors.topMargin: -10; anchors.bottomMargin: -10
          hoverEnabled: true
          preventStealing: true
          cursorShape: root.dragFrom !== "" ? Qt.ClosedHandCursor : Qt.PointingHandCursor
          property point start
          property bool dragged: false
          property int pressWs: 0      // pressed on a dot that isn't showing: drag from that workspace
          onEntered: {
            unhover.stop(); root.pillHover = true; root.pending = pill.monitorName
            root.hovered = pill.monitorName
          }
          // Only the pill the mouse was last on counts as left (enter/leave between
          // two pills can arrive in either order).
          onExited: if (root.pending === pill.monitorName) { root.pillHover = false; unhover.restart() }
          onPressed: (m) => {
            start = Qt.point(m.x, m.y); dragged = false
            const d = root.dotNear(dots, mapToItem(dots, m.x, m.y).x)
            pressWs = d && !d.on ? d.ws.id : 0
          }
          onPositionChanged: (m) => {
            if (!pressed) return
            if (!dragged && Math.hypot(m.x - start.x, m.y - start.y) > 6) {
              root.dragWs = pressWs
              root.dragFrom = pill.monitorName
              if (root.windowOn(pill.monitorName)) dragged = true
              else { root.dragFrom = ""; root.dragWs = 0 }
            }
            if (dragged) {
              root.dragPos = mapToItem(root, m.x, m.y)
              root.dropOn = root.pillAt(root.dragPos.x, root.dragPos.y)
              root.dropWs = root.dropOn ? root.slotAt(root.dragPos.x) : 0
            }
          }
          onReleased: {
            // Drop on another monitor, or on a different workspace of this one.
            if (dragged && root.dropOn && (root.dropOn !== root.dragFrom || root.dropWs || root.dragWs))
              root.moveWindow(root.dragFrom, root.dropOn, root.dropWs)
            root.dragFrom = ""; root.dropOn = ""; root.dropWs = 0; root.dragWs = 0
          }
          // A click (no drag) on a dot goes to that workspace.
          onClicked: (m) => {
            if (dragged) return
            const d = root.dotNear(dots, mapToItem(dots, m.x, m.y).x)
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
