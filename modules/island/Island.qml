import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"

// Island — one per monitor. A see-through strip across the top of the
// screen that holds the pill in the middle and keeps windows below it.
PanelWindow {
  id: island

  required property var modelData   // the monitor this island is on
  screen: modelData

  property bool hidden: false        // Omarchy's "hide bar" toggle

  anchors { top: true; left: true; right: true }
  color: "transparent"
  implicitHeight: Sizes.reserved + Sizes.expandedHeight  // room to grow into
  exclusiveZone: hidden ? 0 : Sizes.reserved
  WlrLayershell.namespace: "dankshell-island"
  WlrLayershell.layer: WlrLayer.Top

  // Only the pill takes clicks; the empty strip around it lets them through.
  mask: Region { item: pill }

  Pill {
    id: pill
    visible: !island.hidden
    anchors.horizontalCenter: parent.horizontalCenter
    y: Sizes.gapFromEdge

    readonly property bool hovered: hover.hovered
    width: Math.max(Sizes.collapsedWidth, closed.implicitWidth + Sizes.barHeight) + (hovered ? Sizes.hoverLift * 2 : 0)
    height: Sizes.barHeight + (hovered ? Sizes.hoverLift : 0)
    radius: height / 2

    HoverHandler { id: hover }

    Closed {
      id: closed
      anchors.centerIn: parent
    }
  }
}
