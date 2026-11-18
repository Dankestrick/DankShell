import QtQuick
import "../"

// Slider — a fat rounded bar you drag, with its icon sitting inside the fill
// (the look from saneAspect's control center). value is 0 to 1.
Rectangle {
  id: slider

  property real value: 0
  property string icon: ""
  signal moved(real value)
  signal iconClicked()

  implicitHeight: 30
  radius: height / 2
  color: Theme.surfaceRaised

  Rectangle {
    id: fill
    height: parent.height
    radius: parent.radius
    width: Math.max(parent.height, parent.width * slider.value)
    color: Theme.accent
    Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Motion.ms(Motion.hover); easing.type: Easing.OutCubic } }
  }

  MouseArea {
    id: drag
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    function set(x) { slider.moved(Math.max(0, Math.min(1, x / width))) }
    onPressed: (m) => { if (m.x > slider.height) set(m.x) }
    onPositionChanged: (m) => { if (pressed && m.x > slider.height) set(m.x) }
    onClicked: (m) => { if (m.x <= slider.height) slider.iconClicked() }
    onWheel: (w) => slider.moved(Math.max(0, Math.min(1, slider.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
  }

  Icon {
    anchors.verticalCenter: parent.verticalCenter
    x: (slider.height - width) / 2
    name: slider.icon
    filled: true
    color: Theme.surface
  }
}
