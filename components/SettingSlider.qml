import QtQuick
import "../"

// SettingSlider — saneAspect's settings row: the name on the left, the value
// on the right, a thin slider under them. Moves live while you drag.
Item {
  id: row
  property string label: ""
  property real value: 0
  property real min: 0
  property real max: 100
  property real step: 1
  property string unit: ""
  property bool changed: false   // not the default: the value is lit
  signal moved(real value)

  width: parent ? parent.width : 300
  implicitHeight: 52

  readonly property real frac: (value - min) / (max - min)
  function snap(f) {
    const v = min + Math.max(0, Math.min(1, f)) * (max - min)
    const s = Math.round(v / step) * step
    return Math.round(s * 1000) / 1000
  }
  function show(v) { return (step < 1 ? v.toFixed(2) : Math.round(v)) + (unit ? " " + unit : "") }

  Text {
    y: 6
    text: row.label
    color: Theme.text
    font.family: Theme.fontText
    font.pixelSize: 12
  }
  Text {
    y: 6
    anchors.right: parent.right
    text: row.show(row.value)
    color: row.changed ? Theme.accent : Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 11
  }
  Item {
    id: track
    anchors.left: parent.left
    anchors.right: parent.right
    y: 28
    height: 18
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.surface }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * Math.max(0, Math.min(1, row.frac)); height: 4; radius: 2; color: Theme.accent }
    Rectangle {
      width: 14; height: 14; radius: 7
      anchors.verticalCenter: parent.verticalCenter
      x: Math.max(0, Math.min(parent.width - width, parent.width * row.frac - width / 2))
      color: Theme.text
      scale: area.pressed ? 1.2 : 1
      Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.hover) } }
    }
    MouseArea {
      id: area
      anchors.fill: parent
      anchors.topMargin: -6
      anchors.bottomMargin: -6
      cursorShape: Qt.PointingHandCursor
      function at(x) { return row.snap(x / track.width) }
      onPressed: (m) => row.moved(at(m.x))
      onPositionChanged: (m) => { if (pressed) row.moved(at(m.x)) }
      // The scroll wheel scrolls the page; only a click or drag changes the value.
      onWheel: (w) => w.accepted = false
    }
  }
  Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.edge }
}
