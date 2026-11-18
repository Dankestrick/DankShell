import QtQuick
import "../"

// Swatches — a row of color dots; the picked one gets a ring.
Row {
  id: sw
  property var colours: []
  property string current: ""
  signal picked(string colour)

  spacing: 7
  opacity: enabled ? 1 : 0.45

  Repeater {
    model: sw.colours
    Rectangle {
      required property var modelData
      readonly property bool here: String(sw.current).toLowerCase() === String(modelData).toLowerCase()
      width: 24; height: 24; radius: 12
      color: modelData
      border.width: here ? 3 : 1
      border.color: here ? Theme.text : Qt.rgba(0, 0, 0, 0.4)
      MouseArea { anchors.fill: parent; anchors.margins: -2; enabled: sw.enabled; cursorShape: Qt.PointingHandCursor; onClicked: sw.picked(modelData) }
    }
  }
}
