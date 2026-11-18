import QtQuick
import "../"

// Pill — the rounded black surface the island is drawn on.
// Its size and corners animate, so it can stretch into any state.
Rectangle {
  id: pill

  color: Theme.surface
  border.color: Theme.edge
  border.width: 1
  antialiasing: true

  Behavior on width {
    NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Motion.moveEasing; easing.overshoot: Motion.overshoot }
  }
  Behavior on height {
    NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Motion.moveEasing; easing.overshoot: Motion.overshoot }
  }
  Behavior on radius {
    NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic }
  }
}
