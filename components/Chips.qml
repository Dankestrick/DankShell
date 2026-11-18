import QtQuick
import "../"

// Chips — a row of choices; the picked one is lit. `model` = list of labels.
Row {
  id: chips
  property var model: []
  property int current: -1
  signal picked(int index)

  spacing: 6
  opacity: enabled ? 1 : 0.45

  Repeater {
    model: chips.model
    Rectangle {
      required property var modelData
      required property int index
      readonly property bool here: index === chips.current
      width: Math.max(56, t.implicitWidth + 22)
      height: 28
      radius: 14
      color: here ? Theme.accent : Theme.surface
      Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
      Text { id: t; anchors.centerIn: parent; text: modelData; color: parent.here ? Theme.surface : Theme.text; font.family: Theme.fontText; font.pixelSize: 11; font.weight: parent.here ? Font.DemiBold : Font.Normal }
      MouseArea { anchors.fill: parent; enabled: chips.enabled; cursorShape: Qt.PointingHandCursor; onClicked: chips.picked(index) }
    }
  }
}
