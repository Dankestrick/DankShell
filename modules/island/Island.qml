import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"

// Island — one per monitor. A see-through strip across the top of the
// screen that holds the pill in the middle and keeps windows below it.
//
// States (one surface that stretches, never a new box):
//   closed  → just the clock
//   bubble  → mouse touched it: grows a little right away
//   hover   → mouse rested a moment: medium card (clock, date, music, workspaces)
PanelWindow {
  id: island

  required property var modelData   // the monitor this island is on
  screen: modelData

  property bool hidden: false        // Omarchy's "hide bar" toggle
  property string state: "closed"

  anchors { top: true; left: true; right: true }
  color: "transparent"
  implicitHeight: Sizes.reserved + Sizes.expandedHeight  // room to grow into
  exclusiveZone: hidden ? 0 : Sizes.reserved
  WlrLayershell.namespace: "dankshell-island"
  WlrLayershell.layer: WlrLayer.Top

  // Only the pill takes clicks; the empty strip around it lets them through.
  mask: Region { item: pill }

  // ── Hover timing ──────────────────────────────
  Timer { id: openTimer; interval: Motion.openDelay; onTriggered: if (hover.hovered) island.state = "hover" }
  Timer { id: closeTimer; interval: Motion.closeDelay; onTriggered: if (!hover.hovered) island.state = "closed" }

  Connections {
    target: hover
    function onHoveredChanged() {
      if (hover.hovered) {
        closeTimer.stop()
        if (island.state === "closed") island.state = "bubble"
        openTimer.restart()
      } else {
        openTimer.stop()
        closeTimer.restart()
      }
    }
  }

  // ── The pill ──────────────────────────────────
  Pill {
    id: pill
    visible: !island.hidden
    clip: true
    anchors.horizontalCenter: parent.horizontalCenter
    y: Sizes.gapFromEdge

    readonly property int closedWidth: Math.max(Sizes.collapsedWidth, closed.implicitWidth + Sizes.barHeight)

    width: island.state === "hover" ? Sizes.hoverWidth
         : island.state === "bubble" ? closedWidth + Sizes.hoverLift * 2
         : closedWidth
    height: island.state === "hover" ? Sizes.hoverHeight
          : island.state === "bubble" ? Sizes.barHeight + Sizes.hoverLift
          : Sizes.barHeight
    radius: island.state === "hover" ? Sizes.radiusHover : height / 2

    HoverHandler { id: hover }

    Closed {
      id: closed
      anchors.centerIn: parent
      opacity: island.state === "hover" ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
    }

    Hover {
      width: Sizes.hoverWidth
      height: Sizes.hoverHeight
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      screenName: island.modelData.name
      opacity: island.state === "hover" ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
    }
  }
}
