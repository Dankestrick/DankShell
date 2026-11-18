import QtQuick
import "../"

// SliderRow — icon, a thin slider and its value on the right.
// The plugin is told when you let go (or live while dragging if `live`).
Item {
  id: row
  property string icon: ""
  property real value: 0
  property string text: ""
  property bool live: false
  property bool iconClick: false
  signal moved(real value)
  signal iconClicked()

  width: parent ? parent.width : 300
  implicitHeight: 30
  opacity: enabled ? 1 : 0.45

  property real dragValue: value
  readonly property real shown: area.pressed ? dragValue : value

  Icon {
    id: ic
    anchors.verticalCenter: parent.verticalCenter
    name: row.icon
    color: Theme.textDim
    MouseArea { anchors.fill: parent; anchors.margins: -4; enabled: row.iconClick && row.enabled; cursorShape: Qt.PointingHandCursor; onClicked: row.iconClicked() }
  }
  Item {
    id: track
    anchors.left: ic.right
    anchors.leftMargin: 10
    anchors.right: val.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    height: 20
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.surface }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * Math.max(0, Math.min(1, row.shown)); height: 6; radius: 3; color: Theme.accent }
    Rectangle {
      width: 14; height: 14; radius: 7
      anchors.verticalCenter: parent.verticalCenter
      x: Math.max(0, Math.min(parent.width - width, parent.width * row.shown - width / 2))
      color: Theme.text
    }
    MouseArea {
      id: area
      anchors.fill: parent
      enabled: row.enabled
      cursorShape: Qt.PointingHandCursor
      function at(x) { return Math.max(0, Math.min(1, x / width)) }
      onPressed: (m) => { row.dragValue = at(m.x); if (row.live) row.moved(row.dragValue) }
      onPositionChanged: (m) => { if (pressed) { row.dragValue = at(m.x); if (row.live) row.moved(row.dragValue) } }
      onReleased: if (!row.live) row.moved(row.dragValue)
      // The scroll wheel scrolls the page; only a click or drag changes the value.
      onWheel: (w) => w.accepted = false
    }
  }
  Text {
    id: val
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 38
    horizontalAlignment: Text.AlignRight
    text: row.text
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 11
  }
}
